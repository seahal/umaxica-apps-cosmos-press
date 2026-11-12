# DatabaseConsistency static length proof

- Main HEAD: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5`; extensive pre-existing uncommitted work was
  preserved.
- Runtime package: `database_consistency 3.0.16`, using the already-configured local fork.
- Nested checker fork HEAD: `d5d1781f3d642b428d6a9654099b0cd96ce52fd8`; the fork has a local
  uncommitted patch and is ignored by the parent repository. The patch below must travel with that
  dependency; the parent diff alone does not contain it.
- The checked published comparison package, `umaxica-database-consistency` 3.1.1, has the same
  missing positive-length inference. Updating to that version alone does not resolve this false
  positive.
- Exact built-in Active Model / Active Record positive static length validation rejects nil on
  creation. The checker previously failed to recognize that proof for retained digest columns. This
  general checker correction adds no model names, connection names, exclusions or disabled checks.
- Custom subclasses, nil/blank-permitting options, conditional predicates, update-only or
  create-excluded contexts, dynamic bounds and zero bounds remain conservative. No application
  predicates or dynamic bounds execute during inspection.
- `bundle exec ruby test/unit/database_consistency_length_nullability_test.rb`: **4 tests, 45
  assertions, zero failures/errors**. These use actual framework validators and column metadata,
  including a custom permissive subclass that must remain reported.
- `RAILS_ENV=test bundle exec database_consistency`: after the database/model improvements, **exit
  0, zero warnings**. No configuration file was provided. This is a checker result; migration, raw
  PostgreSQL constraint and concurrency proofs are recorded separately.

## Local dependency patch

```diff
diff --git a/lib/database_consistency/checkers/column_checkers/null_constraint_checker.rb b/lib/database_consistency/checkers/column_checkers/null_constraint_checker.rb
index 3975a68..3d1d454 100644
--- a/lib/database_consistency/checkers/column_checkers/null_constraint_checker.rb
+++ b/lib/database_consistency/checkers/column_checkers/null_constraint_checker.rb
@@ -6,9 +6,11 @@ module DatabaseConsistency
     class NullConstraintChecker < ColumnChecker
       Report = ReportBuilder.define(
         DatabaseConsistency::Report,
-        :association_name
+        :association_name,
       )

+      POSITIVE_LENGTH_KEYS = %i(is minimum).freeze
+
       private

       # We skip check when:
@@ -45,7 +47,7 @@ module DatabaseConsistency
           error_slug: error_slug,
           error_message: nil,
           association_name: belongs_to_association&.name&.to_s,
-          **report_attributes
+          **report_attributes,
         )
       end

@@ -53,6 +55,7 @@ module DatabaseConsistency
         validator?(:presence, column.name) ||
           validator?(:inclusion, column.name) ||
           numericality_validator_without_allow_nil? ||
+          positive_length_validator? ||
           nil_exclusion_validator? ||
           (belongs_to_association && validator?(:presence, belongs_to_association.name))
       end
@@ -62,7 +65,7 @@ module DatabaseConsistency
       end

       def timestamp_field?
-        model.record_timestamps? && %w[created_at updated_at].include?(column.name)
+        model.record_timestamps? && %w(created_at updated_at).include?(column.name)
       end

       def nil_exclusion_validator?
@@ -81,6 +84,28 @@ module DatabaseConsistency
         end
       end

+      # Rails' built-in positive exact/minimum length checks reject nil without a separate
+      # presence declaration. Prove only static creation constraints; never run application
+      # predicates or dynamic bounds while inspecting a model.
+      def positive_length_validator?
+        model.validators.any? do |validator|
+          builtin = validator.instance_of?(ActiveModel::Validations::LengthValidator) ||
+            validator.instance_of?(ActiveRecord::Validations::LengthValidator)
+          next false unless builtin && Helper.check_inclusion?(validator.attributes, column.name)
+
+          options = validator.options
+          next false if options[:allow_nil] || options[:allow_blank]
+          next false if options.key?(:if) || options.key?(:unless)
+          next false if options[:on] && Array(options[:on]).exclude?(:create)
+          next false if Array(options[:except_on]).include?(:create)
+
+          POSITIVE_LENGTH_KEYS.any? do |key|
+            bound = options[key]
+            bound.is_a?(Integer) && bound.positive?
+          end
+        end
+      end
+
       def validator?(kind, attribute)
         model.validators.any? do |validator|
           validator.kind == kind && Helper.check_inclusion?(validator.attributes, attribute)
@@ -88,9 +113,10 @@ module DatabaseConsistency
       end

       def belongs_to_association
-        @belongs_to_association ||= model.reflect_on_all_associations.find do |r|
-          r.belongs_to? && Helper.check_inclusion?([r.foreign_key, r.foreign_type], column.name)
-        end
+        @belongs_to_association ||=
+          model.reflect_on_all_associations.find do |r|
+            r.belongs_to? && Helper.check_inclusion?([r.foreign_key, r.foreign_type], column.name)
+          end
       end
     end
   end
```
