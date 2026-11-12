# Remove databases Press does not own

Status: local retirement implementation verified. The read-only workflow update remains blocked; the
preceding DatabaseConsistency task resumed after the retirement regression boundary below.

## Revision and scope

- HEAD: `ec34b0a5750c75dc0765fa8ae9e585e3be1ab4d5` (branch `feature`). Extensive staged, unstaged
  and untracked changes were present before this task and affect results. No reset, stash, revert or
  unrelated formatting was performed.
- The preceding DatabaseConsistency improvement task was paused for this owner-directed retirement.
- Keep: `primary`, `queue`, `storage`, `chronicle`, `publishing`, `rp_edit_org`. Their 64
  migration/dump artifacts were fingerprinted before removal; current comparison reports no changes.
- Retire from Press: `app_zenith`, `org_zenith`, `avatar`, `app_setting`, `org_setting`,
  `com_setting`, `app_signal`, `org_signal`, `occurrence`, `op_base_app`, `op_base_org`, `search`,
  and the eight non-Edit RP cells. Governance and Access ownership follows the task's owner
  decisions of 2026-11-12.
- Acceptance: only retained DB connections and models; no foreign-only runtime paths; explicit
  unavailable for retained paths requiring removed data; public Publishing reads and external Access
  Edit authentication preserved; development/test preparation and requested gates executed.
- The user separately authorized retained code adjustments with all six schemas fixed. An RP
  principal is not a Governance authorization or author-profile substitute. Inbound assertion
  validation cannot silently omit replay protection.
- No physical database or bucket was deleted. Recovery for source retirement is review of the
  existing dirty worktree and the private pre-removal source snapshot; this is not production
  deployment authorization.

## Baseline

`PARALLEL_WORKERS=1 bin/rails test` before retirement: **7898 runs, 63230 assertions, 37 failures,
15 errors, 0 skips**. This includes unfinished Red tests from the paused task; failures are not a
clean baseline. Pending generated-position and restoration-index tests must remain meaningful until
that task resumes.

## Observed implementation checkpoints

- Prism inventory: 922 model source files, 835 classes; 604 exclusively retired ORM classes/files
  removed; no mixed retained/retired ORM file.
- Removed 22 foreign migration directories (including principal histories owned by the retired
  zenith connections) and 21 foreign dump/artifact files.
- Reduced `database.yml` to six writers and four replicas per environment; retained connection
  values unchanged.
- Retention retains exactly four Chronicle families. Outbound Edit assertions remain; unavailable
  inbound replay authority raises an explicit dependency error.
- Removed foreign preference hydration and avatar-only source paths. Edit layout no longer reads
  persisted theme preferences.
- `db/seeds.rb` now retains the existing Chronicle catalogs, FQDN initialization and Publishing
  sample lifecycle only.

## Verification still open

Rails cold boot, static allow-list checks, remaining-reference audit, development/test `db:prepare`,
requested full gates, fail-closed requests, public rendering and Edit sign-in verification are not
yet complete. No success is asserted for them.

## Documentation handoff

Per the user, existing docs/ADRs/checklists/diagrams are not rewritten. The obsolete description
inventory will be recorded here after the final reference audit, including
`adr/docs-help-news-discussion-moderation-notification.md`. Claude owns those updates.

## Observed gate checkpoint

- Full `bundle exec erb_lint --lint-all`: 855 files, no errors.
- Full `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`: zero errors and warnings.
- Interim `bin/rubocop`: 1491 files, 37 correctable offenses in changed source/tests; correction and
  final rerun pending.
- `bun run check`: formatting, lint, type checking and OpenAPI lint passed; bundle verification
  failed because its `git diff --exit-code` sees existing uncommitted split bundles against HEAD.
  This command regenerates the three bundles; no source OpenAPI contract was edited for retirement.
  Final attribution remains open.
- `.github` is mounted read-only (`ro` confirmed with `findmnt`): necessary old workflow DB lists
  cannot be written. A minimal patch is being prepared; CI steps are not redesigned.

### Documentation references requiring owner review

The following exact files contain retired DB or ownership descriptions. This is a reference
inventory, not a declaration that every sentence is obsolete; historical/superseded decisions retain
provenance. No listed document was rewritten. Locations are the observed line numbers at this
checkpoint.

- `adr/README.md` (lines 100,356,357).
- `adr/activity-journal-chronicle-db-model-naming.md` (lines 51).
- `adr/authority-lifecycle-table-policy.md` (lines 148,151).
- `adr/avatar-account-bridge-boundary.md` (lines 14).
- `adr/chronicle-audit-db-consolidation.md` (lines 18,42,54,80,93).
- `adr/chronicle-audit-implementation-guidance.md` (lines 43).
- `adr/cosmos-common-database-connections.md` (lines 25,26,41,46,48,60,62,67,69).
- `adr/cosmos-sphere-surfaces-and-rp-independence.md` (lines 19,23,53).
- `adr/database-names-without-region.md` (lines 9).
- `adr/database-trigger-usage-boundary.md` (lines 146,195).
- `adr/emergency-secret-credential-commit-acknowledgement.md` (lines 26,40,49,67).
- `adr/four-app-solid-cache-and-solid-queue.md` (lines 73).
- `adr/global-regional-database-ownership.md` (lines
  49,102,110,115,117,133,154,156,198,200,201,217,264,266,299,314,321).
- `adr/identity-centric-aaa-architecture.md` (lines 121).
- `adr/identity-db-scope-reduction-and-solid-setup.md` (lines 61,63,64,72,79,87,89).
- `adr/org-actor-operator-naming.md` (lines 22).
- `adr/org-entra-id-sign-in-boundary.md` (lines 9,60,62,65,83,92,94,166).
- `adr/owner-api-openapi-description-deferred.md` (lines 11).
- `adr/preference-soft-bubble-doctrine.md` (lines 17,83,85,87,116,117,119,127,128,129).
- `adr/principal-zenith-physical-consolidation.md` (lines 34,35,40,41).
- `adr/read-only-content-surfaces-in-rails.md` (lines 98,100).
- `adr/setting-preference-remove-polymorphic-owner.md` (lines 5).
- `adr/sign-up-flow-admission-binding-and-cardinality.md` (lines 113).
- `adr/staging-aurora-postgresql-topology.md` (lines 22,23,24,27).
- `adr/surface-database-connection-naming.md` (lines 34,35,37,38,42,45,46,53,54,60,61,85,86,88).
- `adr/unified-enforcement.md` (lines 174,243,495,754,757,831,910).
- `docs/DB_ID_BIGINT_SHIFT_AND_FK_FIX.md` (lines 59).
- `docs/architecture/actor-naming.md` (lines 33,34).
- `docs/architecture/avatar-account-bridge.md` (lines 15).
- `docs/architecture/avatar-authority-contract-proposal.md` (lines 10,44).
- `docs/architecture/avatar-social-graph.md` (lines 38,41,43).
- `docs/architecture/database-authority-placement.md` (lines 4,30,31,60,97,102,105,109,118,120).
- `docs/architecture/database-boundaries.md` (lines
  4,5,8,29,30,31,53,54,56,57,61,67,68,69,75,76,96,97,99).
- `docs/architecture/dds.md` (lines 52,53).
- `docs/architecture/hld.md` (lines 33,34).
- `docs/architecture/model-database-inventory.md` (lines
  5,6,7,99,100,101,102,103,104,105,106,107,108,115,116,121,122,125,126,127,128,129,130,131,132,134,135,143,145,146,147,148,149,153,157,158,160,161,162,163,171,172,173,174,175,176,180,183,184,185,186,187,188,189,197,198,199,200,201,202,206,210,211,212,213,214,215,216,217,218,220,224,225,226,227,228,229,230,231,232,251,252,253,254,255,256,257,258,259,260,266,267,268,269,270,271,280,281,282,289,290,291,292,293,294,295,296,303,305,306,308,309,310,311,328).
- `docs/architecture/op-rp-ownership-manifest.md` (lines 21,22,25,26,27,37,38,40).
- `docs/architecture/persona-organization-authority.md` (lines 14,16,242).
- `docs/architecture/preference.md` (lines 103).
- `docs/architecture/press-database-retention.md` (lines 12,13,14).
- `docs/architecture/principal-zenith-membership-organization-placement.md` (lines
  4,69,98,102,103,105,106,108,109,111,112,114,115,117,118,119,120,125,126,137,180,230,239,240,242,243,250,267,271,272,275,276,280,281,283,284,286,287,289,290,291).
- `docs/architecture/regional-content.md` (lines 5,6).
- `docs/architecture/sns-subject-resource-grill.md` (lines
  282,363,380,408,422,467,486,500,514,528,541).
- `docs/audits/rails-intended-functionality-audit.md` (lines 227).
- `docs/checklists/avatar-ownership.md` (lines 57,71,80,81,134,141,164,166).
- `docs/checklists/identifier-contracts.md` (lines 163,253,272,273,279,343).
- `docs/dds.md` (lines 278,281).
- `docs/hld.md` (lines 30,93,201,202,203,204,206,207,208,209,214).
- `docs/mermaid/README.md` (lines 63).
- `docs/mermaid/idp-state-machine-storage-topology.md` (lines 5612).
- `docs/mermaid/idp-state-machine-transition-inventory.md` (lines 3742,3771,4270,4413,5126).
- `docs/mermaid/idp-state-value-coverage.md` (lines 3406,3435,3917,4051,4695).
- `docs/operations/aws-production-service-inventory.md` (lines 249).
- `docs/operations/db-workflow.md` (lines 10,36,37,41,144,148,160,171,172,175,235,422).
- `docs/reference/DB_ID_BIGINT_SHIFT_AND_FK_FIX.md` (lines 65).
- `docs/reference/identifier-conventions.md` (lines 107,134,135,144).
- `docs/runbooks/device-session-token-integrity-rollout.md` (lines 3,4).
- `docs/security/unified-enforcement.md` (lines 120).
- `docs/service-layer-design.md` (lines 91,94,157,161,330).
- `docs/srs.md` (lines 174).
- `plans/2026-10-28-baseline-important-test-set.md` (lines 20).
- `plans/2026-10-30-wu7-com-preference-shape-review.md` (lines 24,66).
- `plans/2026-11-07-handoff-status.md` (lines 98,102,420).
- `plans/2026-11-07-machine-handoff-closure.md` (lines 106,107,108).
- `plans/archive/0001-op-rp-separation/implementation-plan.md` (lines
  284,308,309,310,311,315,316,317,319,372,374,393,395,404,1672).
- `plans/archive/0001-op-rp-separation/implementation-reports.md` (lines 174,175).
- `plans/archive/0001-op-rp-separation/planning-discussion.md` (lines
  61,73,74,75,76,80,81,82,83,84,222,230,945,946,947,948,952,953,954,956,976,978,1921,1923,2102,2372,2431,2626).
- `plans/archive/0002-authentication-cycle-2026-10/critical-review.md` (lines 762).
- `plans/archive/0002-authentication-cycle-2026-10/work-unit-definitions.md` (lines
  2044,2446,2468,2511,2855).
- `plans/archive/0003-authentication-handoff-work-logs/five-experience-consent-affinity-log.md`
  (lines
  41,42,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,247,248,350,538,539,672,778,987).
- `plans/archive/0003-authentication-handoff-work-logs/six-implementation-notes.md` (lines
  111,113,137).
- `plans/archive/0003-authentication-handoff-work-logs/two-design-work-log.md` (lines 1379).
- `plans/archive/0003-authentication-handoff-work-logs/zero-agent-message-board.md` (lines
  802,861,1357,1359,1360,1380,1478,1531,1544,1953,1955,1987,2081,2251,2253,2254,2301,2323,2324,2383,2460).
- `plans/archive/customer-preferences-move-to-com-preference-db.md` (lines 9,150).
- `plans/archive/staff-preference-move-to-operator-db.md` (lines 57,190).
- `plans/backlog/2026-09-17-integrated-hardening-plan.md` (lines
  1024,1040,1171,1214,1215,1218,1219,2220,2303,2337,2408).
- `plans/backlog/2026-09-25-avatar-image-and-emergency-credential-decisions.md` (lines 50,61).
- `plans/backlog/2026-09-26-integrated-auth-remaining-ledger.md` (lines 44).
- `plans/backlog/2026-10-20-core-rp-bridge-cardinality.md` (lines 14).
- `plans/backlog/2026-10-20-cross-database-atomicity-refactoring.md` (lines 19,20).
- `plans/backlog/cross-database-model-associations-audit.md` (lines
  29,30,31,37,38,39,57,58,66,67,69,72,83,166,168,211).
- `plans/backlog/database-improvements.md` (lines 7,14,18,24,31).
- `plans/backlog/legacy-preference-models-retirement-plan.md` (lines 45,78).
- `plans/backlog/mcp-warp-edit-single-connection-design.md` (lines 97,99).
- `plans/backlog/service-layer-design.md` (lines 91,94,158,162,343).
- `plans/backlog/zenith-placement-candidate-models.md` (lines 29,30,31,32,48,49).
- `research/2026-07-21-preference-lifecycle-hardening-implementation.md` (lines 122).
- `research/2026-07-21-preference-lifecycle-sign-out-audit.md` (lines 20).
- `research/2026-10-22-test-value-audit/inventory/rails-jobs.md` (lines 57,59).
- `research/2026-10-22-test-value-audit/inventory/rails-models-a.md` (lines
  707,726,737,1196,1197,1198,1199,1200,1201,1202,1203,1204,1205,1206,1207,1208,1209,1210,1411,1422,1423,1506,1507,1508,1580,1581,1582,1583,1584,1585,1586,1587,1588,1589,1590,1591,1592).
- `research/2026-10-22-test-value-audit/inventory/rails-models-concerns.md` (lines 296).
- `research/2026-10-22-test-value-audit/inventory/rails-models-e.md` (lines 290,291).
- `research/2026-10-22-test-value-audit/inventory/rails-models-m.md` (lines 140).
- `research/2026-10-22-test-value-audit/inventory/rails-models-o.md` (lines
  37,38,39,75,101,392,1558,1570,1581,1604).
- `research/2026-10-22-test-value-audit/inventory/rails-models-r.md` (lines 351).
- `research/2026-10-22-test-value-audit/inventory/rails-models-s.md` (lines 13,14).
- `research/2026-10-22-test-value-audit/inventory/rails-models-t.md` (lines 13).
- `research/2026-10-22-test-value-audit/inventory/rails-operations.md` (lines 201,224).
- `research/2026-10-22-test-value-audit/inventory/rails-policies.md` (lines 187,212,531,883).
- `research/2026-10-22-test-value-audit/inventory/rails-services-acme.md` (lines 39).
- `research/2026-10-22-test-value-audit/inventory/rails-services-root.md` (lines 572,955,1001).
- `research/2026-10-22-test-value-audit/inventory/rails-services-sign_up.md` (lines 29).
- `research/2026-10-22-test-value-audit/inventory/rails-tooling.md` (lines 132).
- `research/app-secret-persistence-shape-proposal.md` (lines 11,20,31,39,49).
- `research/base-secret-core-integration.md` (lines 29).
- `research/implementation/2026-06-30-principal-zenith-physical-consolidation.md` (lines 72).
- `research/implementation/2026-08-22-entra-org-continuation-audit.md` (lines 137).
- `research/implementation/2026-09-03-cms-architecture-remediation-phase-1.md` (lines 20).
- `research/implementation/2026-09-06-shrine-fakecloud-attachments.md` (lines 12,19).
- `research/local/2026-10-13-one-candidate-0.10-full-history.md` (lines
  107,250,251,787,845,1126,1127,1128,1856,1971).
- `research/local/2026-10-13-two-candidate-0.10-full-history.md` (lines 75,330,1040).
- `research/postgresql-association-fk-review.md` (lines
  16,17,18,19,21,25,27,29,31,32,33,34,35,38,39,40,41,42).
- `research/postgresql-integrity-audit-findings.md` (lines 36,40).
- `research/postgresql-integrity-audit-matrix.md` (lines
  35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,243,244,245,246,247,248,249,262,263,264,265,328,329,330,331,332,333,334,335,336,337,338,339,340,341,342,343,344,345,346,347,348,349,350,351,352,353,354,355,356,526,527,528,529,530,531,532,533,534,535,536,537,538,539,540,541,542,543,544,545,546,547,548,549,550,551,552,553,554,555,556,557,558,588,589,590,591,592,593,594,595,596,597,598,599,600,601,602,603,604,605,606,607,608,609,610,611,612,613,614,615,616,617,618,619,620,621,622,623,624,625,626,627,628,629,630,631,632,633,634,635,636,637,638,639,640,641,642,643,644,645,646,647,648,649,650,651,652,653,654,655,656,657,658,659,660,661,662,663,664,665,666,667,668,669,670,671,672,673,674,675,676,677,678,679,680,681,682,683,684,685,686).
- `research/postgresql-integrity-current-static-inventory.md` (lines 48).
- `research/postgresql-integrity-drift-review.md` (lines
  10,11,13,16,21,22,24,38,40,41,43,44,46,51,53).
- `research/postgresql-not-valid-approval-register.md` (lines
  19,20,21,22,23,24,25,26,27,28,46,47,48,49,50,51,79,80,81,82,83,84,85,86,87,88,89,90,91,178,179,180,181,182,183,184,185,186,187,188,189,190,191,209,210,211,212,213,214,215,216,217,218,219,220,221).
- `specs/authentication-cycle-completion/acceptance.md` (lines 114).
- `specs/avatar-organization-ownership/spec.md` (lines 271,288).
- `specs/browser-flow-state-cookies/spec.md` (lines 184,185,200,201,202,203).
- `specs/cosmos-press-route-ownership/spec.md` (lines 92,93,95).
- `specs/database-consistency-remediation/cascade-review.md` (lines 10,12,14).
- `specs/database-consistency-remediation/current-findings.md` (lines
  57,62,64,65,67,69,70,72,74,75,76,78,95,96,98,99,102,108,110,112,113,114,117,120,122,128,129,130,133,134,136,137,138,140,142,146,148,152,155,156,158,164,165,166,170,172,175,177,178,180,182,183,185,189,190,191,194,200,202,203,205,211,212,221,225,227,234,240,242,248,250,254,260,261,262,265,267,270,277,287,288,290,291,297,298,299,308,311,313,322,328,331,332,335,339,345,353,356,357,358,359,360,363,364,368,370,371,373,374,380,382,383,385,387,388,398,399,401,402,403,407,412,424,428,429,433,436,439,440,441,442,447,455,456,459,468,472,476,478,479,480,486,491,492,493,498,499,503,507,510,524,527,529,533,538,539,541,552,553,555,557,558,567,569,570,575,578,579,580,583,587,591,593,595,596,597,600,612,613,614,615,616,618,620,623,625,626,628,630,636,644,645,653,655,659,663,664,665,675,684,687,688,693,694,697,699,700,704,705,707,710,715,716,718,719,720,721,723,726,728,729,730,731,732,734,736,738,740,746,750,752,757,758,759,761,763,767,770,773,774,778,779,782,784,786,789,796,798,800,802,809,811,814,819,820,824,827,828,830,832,834,837,843,848,849,856,858,864,865,867,871,874,875,876,879,880,882,886,895,898,901,903,905,911,912,913,920,922,924,926,928,931,933,938,939,944,947,949,951,954,960,963,965,968,973,976,982,993,994,997,1011,1014,1017,1028,1040,1042,1043,1046,1050,1051,1052,1053,1054,1055,1058,1065,1070,1075,1079,1081,1083,1085,1091,1093,1102,1105,1106,1109,1112,1121,1122,1127,1132,1133,1136,1139,1141,1149,1152,1153,1155,1158,1166,1169,1174,1176,1177,1178,1180,1182,1185,1188,1190,1193,1195,1199,1200,1201,1203,1208,1213,1214,1215,1216,1223,1225,1226,1231,1234,1237,1243,1247,1250,1252,1254,1255,1260,1261,1266,1288,1290,1292,1297,1298,1300,1304,1310,1312,1316,1317,1319,1321,1327,1328,1330,1334,1338,1341,1346,1347,1350,1351,1353,1354,1355,1358,1365,1367,1370,1373,1374,1378,1384,1385,1390,1393,1394,1398,1401,1403,1404,1406,1407,1409,1411,1423,1424,1426,1430,1435,1437,1438,1439,1441,1449,1458,1462,1463,1464,1467,1468,1471,1473,1482,1488,1493,1497,1499,1507,1510,1515,1516,1517,1518,1520,1521,1524,1533,1536,1540,1541,1543,1544,1545,1549,1550,1555,1556,1563,1565,1568,1571,1572,1576,1580,1583,1586,1598,1599,1600,1602,1604,1608,1609,1617,1620,1625,1627,1629,1636,1639,1642,1643,1644,1645,1647,1654,1657,1659,1662,1663,1668,1669,1676,1678,1679,1680,1681,1684,1688,1692,1695,1696,1697,1700,1705,1706,1714,1715,1716,1719,1720,1722,1724,1725,1729,1730,1740,1743,1744,1754,1756,1761,1766,1769,1773,1779,1783,1784,1788,1802,1804,1810,1812,1813,1814,1815,1818,1823,1829,1831,1833,1841,1844,1848,1851,1861,1863,1866,1868,1869,1871,1872,1873,1875,1878,1880,1884,1889,1891,1897,1899,1906,1907,1912,1914,1915,1916,1920,1927,1928,1931,1939,1941,1943,1951,1952,1954,1955,1959,1960,1961,1963,1966,1968,1969,1975,1985,1986,1987,1988,1991,1992,1994,1997,1998,1999,2002,2006,2008,2015,2018,2023,2024,2029,2032,2033,2036,2037,2038,2040,2041,2042,2044,2046,2048,2052,2057,2058,2062,2064,2065,2070,2084,2086,2087,2090,2096,2097,2100,2101,2105,2108,2110,2114,2116,2119,2120,2125,2126,2135,2143,2145,2154,2160,2161,2162,2166,2169,2170,2171,2173,2175,2179,2180,2188,2191,2198,2201,2208,2218,2219,2220,2221,2223,2224,2225,2227,2230,2235,2239,2243,2244,2245,2248,2250,2251,2254,2262,2263).
- `specs/database-consistency-remediation/cycles.md` (lines 24,25).
- `specs/database-consistency-remediation/decisions.md` (lines 163,167).
- `specs/database-consistency-remediation/equal-key-index-review.md` (lines 21,23,36).
- `specs/database-consistency-remediation/findings.md` (lines
  43,48,50,51,53,55,56,58,60,61,62,64,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,432,433,434,435,436,437,438,439,440,441,442,443,444,445,446,447,448,449,450,451,452,453,454,455,456,457,458,459,460,461,462,463,464,465,466,467,468,469,470,471,472,473,474,475,476,477,478,479,480,481,482,483,484,485,486,487,488,489,490,491,492,493,494,495,496,497,498,499,500,501,502,503,504,505,506,507,508,509,510,511,512,513,514,515,516,517,518,519,520,521,522,523,524,525,526,527,528,529,530,531,532,533,534,535,536,537,538,539,540,541,542,543,544,545,546,547,548,549,550,551,552,553,554,555,556,557,558,559,560,561,562,563,564,565,566,567,568,569,570,571,678,679,680,681,682,683,684,685,686,687,688,689,690,691,692,693,694,695,696,697,698,699,700,701,702,703,704,705,706,707,708,709,710,711,712,713,714,715,716,717,718,719,720,721,722,723,724,725,726,727,728,729,730,731,732,733,734,735,736,737,738,739,740,741,742,743,744,745,746,747,748,749,750,751,752,753,754,755,756,757,758,759,760,761,762,763,764,765,766,767,768,769,770,771,772,773,774,775,776,777,778,779,780,781,782,783,784,785,786,787,788,789,790,791,792,793,794,795,796,797,798,799,800,801,802,803,804,805,806,807,808,809,810,811,812,813,814,815,816,817,818,819,820,821,822,823,824,825,826,827,828,829,830,831,832,833,834,835,836,837,838,839,840,841,842,843,844,845,846,847,848,849,850,851,852,853,854,855,856,857,858,859,860,861,862,863,864,865,866,867,868,1932,1933,1934,1935,1936,1937,1938,1939,1940,1941,1942,1943,1944,1945,1946,1947,1948,1949,1950,1951,1952,1953,1954,1955,1956,1957,1958,1959,1960,1990,1991,1992,1993,1994,1995,1996,1997,1998,1999,2000,2001,2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018,2019,2020,2021,2022,2023,2024,2025,2026,2027,2028,2029,2030,2031,2032,2033,2034,2035,2036,2037,2038,2039,2040,2041,2042,2043,2044,2045,2046,2047,2077,2078,2079,2080,2081,2082,2083,2084,2085,2086,2087,2088,2089,2090,2091,2092,2093,2094,2095,2096,2097,2098,2099,2100,2101,2102,2103,2104,2105,2135,2136,2137,2138,2139,2140,2141,2142,2143,2144,2145,2146,2147,2148,2149,2150,2151,2152,2153,2154,2155,2156,2157,2158,2159,2160,2161,2162,2163,2164,2165,2166,2167,2168,2169,2170,2171,2172,2173,2174,2175,2176,2177,2178,2179,2180,2181,2182,2183,2184,2185,2186,2187,2188,2189,2190,2191,2192,2193,2194,2195,2196,2197,2198,2199,2200,2201,2202,2203,2204,2205,2206,2207,2208,2209,2210,2211,2212,2213,2214,2215,2216,2217,2218,2219,2220,2221,2251,2252,2253,2254,2255,2256,2257,2258,2259,2260,2261,2262,2263,2264,2265,2266,2267,2268,2269,2270,2271,2272,2273,2274,2275,2276,2277,2278,2279).
- `specs/database-consistency-remediation/finite-length-review.md` (lines
  15,16,17,18,19,20,21,29,30,31,32,33,34,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,88,89,90,91,92,93,94,95,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,136,137,138,139,140,141,142,143).
- `specs/database-consistency-remediation/foreign-key-review.md` (lines
  15,16,19,20,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41).
- `specs/database-consistency-remediation/index-review.md` (lines
  102,104,120,121,122,123,124,125,126,127,128,129).
- `specs/database-consistency-remediation/missing-index-review.md` (lines
  11,31,32,33,34,39,40,41,42,43,44,45,46,47,48,49,50,55,56,57,58,63,64,65,66,67,68,69,70,75,76,77,78,79,80,83,84,86,87).
- `specs/database-consistency-remediation/public-id-check-review.md` (lines
  21,22,23,24,25,26,27,28,29,30,31,32,33,34,63,64,65,66,67,68,69,70,71,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,207,208,209,213,214,215,216,217,218,222,223,224,228,229,230,231,232,233,234,235,236,240,241,242).
- `specs/database-consistency-remediation/public-id-review.md` (lines
  25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,65,99,100,101,102,103,104,105,106,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135,136,137,138,139,140,141,142,143,253,254,255,259,260,261,262,263,264,268,269,270,274,275,276,277,278,279,280,281,282,286,287,288).
- `specs/database-consistency-remediation/unique-index-review.md` (lines
  75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,237,238,239,240,241,242,243,244,245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,620,621,622,623,624,630,631,632,633,634,635,636,637,638,639,645,646,647,648,649,655,656,657,658,659,660,661,662,663,664,665,666,667,668,669,675,676,677,678,679).
- `specs/keep-database-consistency/inventory.md` (lines
  58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,91,110,111,112,114,115,117,118,119,120,121,123,124,130).
- `specs/op-mediated-step-up/contracts/o9-implementation-design.md` (lines 10).
- `specs/org-organization-consolidation/inventory.md` (lines 38,74).
- `specs/org-organization-consolidation/report.md` (lines 65).
- `adr/docs-help-news-discussion-moderation-notification.md` (user-identified zenith content-table
  note; review separately from literal connection-name matches).

## Runtime verification checkpoint

- `RAILS_ENV=test bin/rails runner 'puts "boot_ok"'`: passed after deleting foreign eager-load
  dependencies and retired preference JWT initializer validation.
- `RAILS_ENV=development bin/rails db:prepare`: exit 0. This applied previously authored, pending
  migrations from the paused task to the local development databases; no new migration was authored
  for retirement.
- `RAILS_ENV=test bin/rails db:prepare`: exit 0. The exact six retained names were supplied in
  `POSTGRESQL_TEST_PREPARE_DATABASES` because the inherited process environment still held the old
  list and takes precedence over dotenv. The safety guard rejected the obsolete list before any test
  preparation write; it was not bypassed or weakened.
- After preparation: all 64 retained schema-source fingerprints remain unchanged.
- Error-response behavior test first failed because HTML still redirected with flash and did not
  render the expected explicit failure. After removal of the retired client/staff aliases and
  signup-only diagnostics, the response renders its actual error status inline. Green: **2 runs, 13
  assertions, zero failures/errors/skips**; scoped Ruby lint passed. Obsolete existence-only
  alias/redirect wiring tests retired with those wrappers.

## Retained runtime proof checkpoint

- Real PostgreSQL narrow regression: **131 runs, 475 assertions, zero failures/errors/skips**.
  Covers Chronicle historical scalar records and explicit unavailable actor/preference access,
  retention batching and lifecycle/failure propagation, policy denial, Actor context boundaries,
  external JWT rejection and nearest temporal boundaries. Initial test-only catalog/constructor
  setup defects were corrected without weakening assertions.
- The Edit protocol checkpoint passed its five public authorization-code callback tests (PKCE,
  signed nonce, issuer, browser state and replay). The combined protocol run still had one
  test-cookie reinjection defect under investigation; it is not reported green here.
- Full `bin/rails test` initially stopped during test loading on an obsolete retired
  `VerificationBase` consumer. Feature test retirement audit continues; no full-suite pass is
  claimed.
- `RAILS_ENV=test bundle exec database_consistency`: exit **1**, **38** retained warnings: 24
  restoration-reference indexes, 12 ordered snapshot nullability checks, 2 Chronicle uniqueness
  validators. These are the paused task's known outstanding work, preserved for its resumption;
  retirement introduced no new checker group. Solid Queue warnings: **0 observed**. No checker
  configuration/exclusions were added.
- The effective test connection names are exactly: `primary`, `queue`, `storage`, `chronicle`,
  `chronicle_replica`, `publishing`, `publishing_replica`, `rp_edit_org`, `rp_edit_org_replica`,
  `storage_replica`.

- Final focused Edit protocol proof: **30 runs, 201 assertions, zero failures/errors/skips**,
  including public sign-in/callback exchange, CSRF before unsafe refresh, local revocation and
  dependency failures. The prior functional-test cookie issue was corrected by setting the previous
  request's cookie as well as the browser jar; expected refresh count and generation assertions were
  retained.
- Static test retirement closure: zero AST references to 337 actually retired runtime/concern
  definitions and zero references to all 604 removed ORM definitions. Historical audit type strings
  and forbidden diagnostic disclosure samples are reviewed separately from executable constant
  references.

## Whole-suite reconciliation checkpoint

Full-suite attempt 3 executed **3611 runs, 40340 assertions, 61 failures, 37 errors, zero skips**.
This was a diagnostic run, not acceptance. It exposed stale foreign-feature tests and former
Actor/preference lifecycle expectations in retained guards. The pending original schema-contract
tests remain distinct and are not removed to obtain a pass.

The retained-region decision preserves explicit request inputs without fabricating a Governance
preference. Automatic preference-driven `ri=jp`, theme and timezone hydration are removed; valid
explicit OIDC region propagation remains, and invalid supplied regions must fail explicitly.
`docs/architecture/preference.md`, `docs/architecture/controller-lifecycle.md` and their
RI/lifecycle descriptions require Claude's handoff review rather than being silently treated as
current after this owner-directed retirement.

Subsequent focused protocol follow-up: **36 runs, 144 assertions, zero failures/errors/skips**.
External Access transport stays HTTPS with its configured port; the pre-existing no-query policy was
preserved and receives a rejection-before-HTTP test. Former cell bindings reject unknown cells.
Static policy/lifecycle guards retain positive CSRF, credential, cache and authorization-order
assertions.

## Retirement acceptance boundary before resuming schema work

- Final retirement whole-suite run: **3600 runs, 41088 assertions, 26 failures, 12 errors, zero
  skips**. The remaining **38** are exactly the pre-existing original-task Red cases: restoration
  indexes (24 failures), generated taxonomy snapshots (12 setup/schema errors), Client UUID
  uniqueness (1 failure), Operator halt correlation (1 failure). All retirement-caused failures from
  the diagnostic runs were resolved. This is explicitly not a whole-suite pass.
- Focused generic/public-content regression: **172 runs, 3998 assertions, zero
  failures/errors/skips**.
- Final focused protocol/region regression: **35 runs, 285 assertions, zero failures/errors/skips**.
  Missing region is omitted from sign-in rather than replaced; invalid supplied types/values
  return 400. Missing region on logout cannot invent a registered callback: it returns 422 before
  local revocation or external calls, preserving credentials.
- Root input contract Red: invalid region returned 200; Green after typed scalar validation: **2
  runs, 44 assertions, zero failures/errors/skips**. Public root rendering no longer passes an
  unpermitted parameter object to URL generation.
- Final full RuboCop: **1254 files, zero offenses**. Final full ERB lint: **855 files, zero
  errors**. Final full Brakeman: **zero errors, zero security warnings**.
- OpenAPI route guard tightened to the sole retained private Publishing owner API: **6 runs, 31
  assertions, zero failures/errors/skips**. Retired owner routes no longer receive a description
  exemption.
- Final `bun run check`: exit 1 at the unchanged `git diff --exit-code` bundle-vs-HEAD check;
  formatting, lint, type checking and OpenAPI lint passed. SHA256 of all three bundles is identical
  before/after the final generator run. No OpenAPI source description was edited for this task; the
  working tree is intentionally dirty and was not staged/committed to hide that comparison.
- The final retirement comparison again verified **all 64 retained migration/dump source hashes
  unchanged**. This boundary precedes all resumed-task migrations; subsequent intentional schema
  changes belong to that separately authorized task.
- All production `app/`, `lib/`, `config/`, `scripts/` Ruby/Rake sources have zero AST constant
  references to removed ORM definitions. The test audit has zero references to 960 actually retired
  definitions and no missing relative imports. These are static guarantees, not guarantees about
  arbitrary dynamic strings.

### Complete local connection disposition

| Connection family removed from Press                                                                                   | Destination responsibility                  | Physical-database qualification                                   |
| ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | ----------------------------------------------------------------- |
| `app_zenith`, `org_zenith`, including principal and RP record aliases                                                  | Governance                                  | Press bindings removed; no physical instance dropped.             |
| `avatar`                                                                                                               | Governance                                  | Press bindings removed; no physical instance dropped.             |
| `app_setting`, `org_setting`, `com_setting`                                                                            | Governance                                  | Press bindings removed; no physical instance dropped.             |
| `app_signal`, `org_signal`                                                                                             | Governance                                  | Press bindings removed; no physical instance dropped.             |
| `op_base_app`, `op_base_org`                                                                                           | Access                                      | Press bindings removed; no physical instance dropped.             |
| `rp_base_app`, `rp_core_app`, `rp_warp_app`, `rp_palm_app`, `rp_base_org`, `rp_core_org`, `rp_warp_org`, `rp_tech_org` | Their owning services                       | Press bindings removed; no destination deployment inferred.       |
| `occurrence`                                                                                                           | Not Press; destination not established here | Press bindings removed; physical disposition remains unasserted.  |
| `search`                                                                                                               | None; previously no tables                  | Press binding/artifacts removed; physical deletion not attempted. |

All replicas of removed bindings were removed. The six retained connections are `primary`, `queue`,
`storage`, `chronicle`, `publishing`, `rp_edit_org`; only Edit remains in the RP cell catalog. For
the original consistency task, Solid Queue is still EXCLUDED, not a remediation target.

### Intentional remaining name hits

Exact removed connection/abstract-record matches in `app lib config db test src` are limited to:

| Location                                                                                    | Reason                                                                                        |
| ------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `app/models/enforcement_event.rb` (comment: occurrence counters)                            | Ordinary event-counting terminology, not a connection or lookup.                              |
| `app/controllers/concerns/problem_details_rendering.rb` (two comments: occurrence-specific) | RFC 9457 terminology, not the retired database.                                               |
| `test/integration/health_endpoints_test.rb` (two `AppPrincipalRecord` strings)              | Adversarial diagnostic text and explicit non-disclosure assertion; never resolved as a class. |
| `test/integration/health_revision_contract_test.rb` (`AppRpRecord` string)                  | Explicit response non-disclosure assertion.                                                   |
| `test/values/rp_cell_binding_test.rb` (`rp_core_app` string)                                | Proves removed binding raises UnknownCell rather than silently selecting another cell.        |

Concrete old names in the retained Chronicle schema/migration, scalar audit models and 13 historical
fixtures are persisted type vocabulary (Client/Operator/Preference), not foreign model associations;
these must remain to preserve audit history. Tests assert historical scalar preservation and
explicit unavailable dereferencing. Security guard regexes for old token/passkey/flow types
deliberately prohibit reintroduction. Remaining generic words in headers, labels and comments
(Client ID, User-Agent, handle, member) do not resolve removed classes. No removed model or
connection allow-list remains active.

### Blocked workflow and recovery handoff

`.github/workflows/ci.yml` cannot be edited: `findmnt -T` reports `/home/global/workspace/.github`
mounted `ro`; writing raises EROFS. The minimal DB-list-only patch is
`/tmp/press-ci-db-binding.patch`: four preparation lists become the exact six retained writers and
obsolete publication/subscription bindings are deleted. Steps, Solid Queue settings and unrelated
workflow behavior are unchanged in the prepared patch. The patch has **not** been applied, and the
remaining workflow therefore still names retired databases. No remote write or mount bypass was
attempted.

Historical/source recovery snapshots remain private in `/tmp`; no production/shared data recovery
was needed because no such data was changed. The user-owned documentation inventory above is handed
to Claude without rewriting its ADRs/checklists/diagrams.

## Subsequent verified closure

After the separately authorized schema task resumed, final inspection found and fixed the retained
policy's ambient Actor claims dependency. Domain policies now receive the verified request payload
explicitly, require a principal and reject missing/malformed/unknown context; the strict JWT
verifier and anonymous admission rules remain intact. The source wiring and causal Red/Green proofs
are in `2026-11-12-request-policy-claims-C73A.md`.

The final combined non-system suite is **3628 tests / 42011 assertions / zero failures, errors or
skips**, exit 0. The formerly pending 38 database-contract cases now pass. Final coverage remains
below existing configured floors and is not waived. The `.github` EROFS patch and unavailable
destination checkouts remain open. The authoritative final database/check/coverage/rebuild status is
`2026-11-12-keep-database-consistency-final-F5Z0.md`. This does not retroactively claim the earlier
retirement stage changed the six fixed schemas.
