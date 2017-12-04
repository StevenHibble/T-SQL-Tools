CREATE FUNCTION [Tools].[CountSubstring] (@String    VARCHAR(8000)
                                        , @Substring VARCHAR(8000))
/*
This function counts the number of occurances of a certain substring in a string
The table returns a single column: SubstringCount

EXAMPLE: 
SELECT *
FROM [Tools].[CountSubstring] ('how many spaces are in this sentence?', ' ')
SubstringCount
###########
6

This is based off a StackOverflow answer: https://stackoverflow.com/a/738296/5941593
It has been modified to use DATALENGTH instead of LEN (because whitespace at the end of strings are ignored by LEN)
*/
RETURNS TABLE
AS
  RETURN
  SELECT [SubstringCount] = DATALENGTH(@String)-DATALENGTH(REPLACE(@String, @Substring, ''));
GO
