CREATE FUNCTION [Tools].[PadString] (@String   VARCHAR(8000)
                                   , @Pad      CHAR(1)
                                   , @MaxWidth INT) 
/*
This function left-pads a VARCHAR string with any single-character pad (most commonly used for 0-padding integers for sorting)
It pads so that the resulting string is @MaxWidth
If @String is as long as orlonger than @MaxWidth, it is returned unaltered

The returned table only has one column: PaddedString

NOTE: Can be used with [Tools].[SplitString] to fix padding in variable names (e.g. VAR.1, VAR.2, VAR.10) or file names (e.g. file - 1.txt, file - 2.txt, file - 10.txt)
      The strings will have to be reconcatenated

EXAMPLE: 
SELECT * 
FROM (VALUES ('1 '), ('2'), ('10')) [v] (VariableName)
     CROSS APPLY [Tools].[PadString] (VariableName, '0', 3)
PaddedString
###########
001
002
010
*/   
RETURNS TABLE
WITH SCHEMABINDING
AS
  RETURN

  SELECT [PaddedString] = CASE
                            WHEN DATALENGTH(@String) < @MaxWidth THEN REPLICATE(@Pad, @MaxWidth-DATALENGTH(@String)) + @String
                            ELSE @String
                          END;
GO