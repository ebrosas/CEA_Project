SELECT a.*

FROM sys.sysobjects AS a INNER JOIN

sys.syscomments AS b ON a.id = b.id

WHERE b.text LIKE '%StatusHandlingDesc%'
