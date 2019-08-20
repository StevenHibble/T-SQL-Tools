CREATE OR ALTER FUNCTION Tools.TrimDynamicSQL 
 (@SQL VARCHAR(MAX))
/*
This function takes a long string and removes the minimum amount of left-padding to return a cleaner looking string.
I use this when building dynamic SQL in procs. I can clean up the string for printing/selecting.
The table returns a single column: SQL

EXAMPLE: 
SELECT *
FROM (VALUES ('SELECT *
               FROM TableA
               WHERE ColB = 5') ) v(OldSQL)
     CROSS APPLY Tools.TrimDynamicSQL (OldSQL);

OldSQL                         | SQL       
-------------------------------+-----------------
SELECT *                       | SELECT *
               FROM TableA     | FROM TableA
               WHERE ColB = 5  | WHERE ColB = 5
*/
RETURNS TABLE
AS
  RETURN
  WITH CTE_PadLength
       AS (SELECT PadLength = MIN(LinePad)
           FROM Tools.SplitString (@SQL, CHAR(13) + CHAR(10))
                CROSS APPLY (SELECT LinePad = LEN(String) - LEN(LTRIM(String))) lp
           WHERE LinePad > 0),
       CTE_Replace
       AS (SELECT ReplaceThis = CHAR(13)+CHAR(10)+REPLICATE(' ', ISNULL(PadLength, 0))
           FROM CTE_PadLength)
       SELECT [SQL] = REPLACE(@S
