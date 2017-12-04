CREATE FUNCTION [Tools].[RemoveDuplicateCharacter] (@String    VARCHAR(8000)
                                                  , @Character CHAR(1))
/*
This function replaces every string of repeated @Character with a single @Character
This table returns a single column: DedupedString

NOTE: This uses CHAR(17) and CHAR(18) as special characters. @String can't have those.
      CHAR(17) and CHAR(18) are "device control 1" and "device control 2"

EXAMPLE: 
SELECT * 
FROM [Tools].[RemoveDuplicateCharacter] ('too      many   spaces', ' ')
DedupedString
###########
too many spaces
*/
RETURNS TABLE
WITH SCHEMABINDING
AS
  -- Step 1: Replace every value of @Character with non-printable characters (17 + 18)
  -- Step 2: Replace every case where 18 + 17 exists (NOTE: This is the reverse order from Step 1)
  -- Step 3: Replace single remaining 17 + 18 with @Character
      /* Example: @String = 'test1   test2', @Character = ' '
                  Pretend that CHAR(17) = '<'
                               CHAR(18) = '>'
         
         -- Input:  'test1   test2'
         -- Step 1: 'test1<><><>test2'
         -- Step 2: 'test1<>test2'
         -- Step 3: 'test1 test2'
      */
  RETURN
  SELECT [DedupedString] = REPLACE(REPLACE(REPLACE(@String, @Character, CHAR(17)+CHAR(18)), CHAR(18)+CHAR(17), ''), CHAR(17)+CHAR(18), @Character);
GO


