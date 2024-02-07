	--Get the workflow instances
	SELECT * FROM [System.Activities.DurableInstancing].[Instances] a 
	ORDER By CreationTime DESC  

	--Check workflow transaction logs
	SELECT * FROM genuser.WorkflowTransactionLog a
	--WHERE RTRIM(a.WFInstanceID) = '9B87EBE3-1206-492F-A92E-3759194FC470'
	WHERE a.RequisitionNo = 20230046
	ORDER BY a.LogID DESC


/*	Debug:

	BEGIN TRAN T1

	DELETE FROM genuser.WorkflowTransactionLog 

	COMMIT TRAN T1

*/
