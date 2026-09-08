-- Correct kickoff DATES that two independent sources agree we have wrong.
--
-- rsssf.org and whoscored.com were compared against the vault for TPL 2018/19
-- and 2019/20. Where the two sources agree with each other and disagree with
-- us, the vault is corrected; where they conflict with each other, the vault is
-- left alone (it already sides with one of them in every such case).
--
-- Most of these are 2019/20. That season was suspended for COVID in March 2020
-- and resumed in June, finishing on 26 July. Both sources place the resumed
-- fixtures in June and July; the vault had 60 of them in April and May, inside
-- the suspension. The scores were reconciled in an earlier pass but the legacy
-- kickoff dates on those rows were never corrected with them.
--
-- Only the DATE moves. The time of day is kept as it stands -- it was corrected
-- to Tanzanian local time separately and is not in dispute here.

BEGIN;

CREATE TEMP TABLE date_fix (match_id INT PRIMARY KEY, new_date DATE);
INSERT INTO date_fix (match_id, new_date) VALUES
  (365, DATE '2018-09-27'),
  (440, DATE '2019-03-12'),
  (442, DATE '2018-12-03'),
  (522, DATE '2019-01-20'),
  (1003, DATE '2019-12-24'),
  (1004, DATE '2019-12-29'),
  (1007, DATE '2019-12-27'),
  (1035, DATE '2020-07-26'),
  (1036, DATE '2020-07-26'),
  (1037, DATE '2020-07-26'),
  (1038, DATE '2020-07-26'),
  (1039, DATE '2020-07-26'),
  (1040, DATE '2020-07-26'),
  (1041, DATE '2020-07-26'),
  (1042, DATE '2020-07-26'),
  (1043, DATE '2020-07-26'),
  (1044, DATE '2020-07-26'),
  (1045, DATE '2020-07-22'),
  (1046, DATE '2020-07-22'),
  (1047, DATE '2020-07-22'),
  (1048, DATE '2020-07-22'),
  (1049, DATE '2020-07-23'),
  (1050, DATE '2020-07-22'),
  (1051, DATE '2020-07-23'),
  (1052, DATE '2020-07-23'),
  (1053, DATE '2020-07-23'),
  (1054, DATE '2020-07-23'),
  (1057, DATE '2019-12-25'),
  (1058, DATE '2019-12-26'),
  (1061, DATE '2019-12-25'),
  (1079, DATE '2020-02-02'),
  (1081, DATE '2020-02-07'),
  (1090, DATE '2020-06-13'),
  (1091, DATE '2020-03-17'),
  (1094, DATE '2020-07-04'),
  (1095, DATE '2020-07-08'),
  (1096, DATE '2020-07-15'),
  (1097, DATE '2020-07-18'),
  (1098, DATE '2020-07-18'),
  (1100, DATE '2020-07-19'),
  (1101, DATE '2020-07-18'),
  (1102, DATE '2020-07-18'),
  (1103, DATE '2020-07-19'),
  (1104, DATE '2020-07-19'),
  (1105, DATE '2020-06-13'),
  (1106, DATE '2020-07-18'),
  (1107, DATE '2020-07-14'),
  (1108, DATE '2020-07-15'),
  (1109, DATE '2020-07-15'),
  (1110, DATE '2020-07-14'),
  (1111, DATE '2020-07-15'),
  (1112, DATE '2020-07-16'),
  (1113, DATE '2020-07-14'),
  (1114, DATE '2020-07-15'),
  (1115, DATE '2020-07-15'),
  (1116, DATE '2020-07-09'),
  (1117, DATE '2020-07-08'),
  (1118, DATE '2020-07-08'),
  (1119, DATE '2020-07-09'),
  (1120, DATE '2020-07-10'),
  (1121, DATE '2020-07-08'),
  (1122, DATE '2020-07-08'),
  (1123, DATE '2020-07-08'),
  (1124, DATE '2020-07-08'),
  (1146, DATE '2019-12-28'),
  (1216, DATE '2020-01-29'),
  (1218, DATE '2019-12-31'),
  (1238, DATE '2020-01-30'),
  (1240, DATE '2020-07-18'),
  (1254, DATE '2020-02-02'),
  (1263, DATE '2020-02-04'),
  (1275, DATE '2020-02-08'),
  (1278, DATE '2020-02-11'),
  (1512, DATE '2020-03-05'),
  (1538, DATE '2020-06-14'),
  (1539, DATE '2020-06-14'),
  (1540, DATE '2020-06-17'),
  (1541, DATE '2020-06-20'),
  (1542, DATE '2020-06-20'),
  (1543, DATE '2020-06-20'),
  (1544, DATE '2020-06-20'),
  (1545, DATE '2020-06-20'),
  (1546, DATE '2020-06-20'),
  (1547, DATE '2020-06-20'),
  (1548, DATE '2020-06-21'),
  (1549, DATE '2020-06-20');

UPDATE matches m
   SET kickoff_at = f.new_date + (m.kickoff_at AT TIME ZONE 'Africa/Dar_es_Salaam')::time
                    AT TIME ZONE 'Africa/Dar_es_Salaam'
  FROM date_fix f
 WHERE m.id = f.match_id;

\echo 'rows corrected (expected 86):'
SELECT count(*) FROM matches m JOIN date_fix f ON f.match_id = m.id
 WHERE (m.kickoff_at AT TIME ZONE 'Africa/Dar_es_Salaam')::date = f.new_date;

\echo 'any that did not land on the intended date (must be 0):'
SELECT count(*) FROM matches m JOIN date_fix f ON f.match_id = m.id
 WHERE (m.kickoff_at AT TIME ZONE 'Africa/Dar_es_Salaam')::date <> f.new_date;

\echo '2019/20 matches now inside the COVID suspension, Apr-May 2020 (must be 0):'
SELECT count(*) FROM matches
 WHERE competition_edition_id = 17
   AND (kickoff_at AT TIME ZONE 'Africa/Dar_es_Salaam')::date BETWEEN '2020-04-01' AND '2020-05-31';

COMMIT;
