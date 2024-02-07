DECLARE	@reqType		INT,
		@reqTypeNo		INT,
		@processID		INT,
		@reqTypeID		INT	

SELECT	@reqType		= 7,
		@reqTypeNo		= 71

	--Declare all necessary variables Process WF
	DECLARE @transProcessID		INT,
			@processCode		VARCHAR(20),
			@processDesc		VARCHAR(200),
			@processVer			VARCHAR(5),
			@processStatusID	INT

	--Get the Process ID
	SELECT	@processID = b.ReqTypeProcessID, 
			@reqTypeID =  b.ReqTypeID 
	FROM secuser.PAFWF AS a 
		INNER JOIN secuser.RequestType AS b ON a.PAFReqTypeID = b.ReqTypeID
	WHERE a.PAFNo = @reqTypeNo

	SELECT	@processID AS ProcessID, @reqTypeID  AS ReqTypeID

	--Get all workflow activities based on the template
	SELECT a.ActID, a.ActCode, a.ActDesc, a.ActType, a.ActSeq, a.ActNextCode
	FROM SecUser.GenPurposeProcessActivity AS a
	WHERE a.ActProcessID = @processID
	ORDER BY a.ActSeq

	-- Retrieve the Process Workflow
	SELECT	@processCode = a.ProcessCode, 
			@processDesc = a.ProcessDesc, 
			@processVer = a.ProcessVer
	FROM SecUser.GenPurposeProcessWF AS a
	WHERE a.ProcessID = @processID

	SELECT	@processCode AS ProcessCode, @processDesc AS ProcessDesc, @processVer AS ProcessVer

	--Set the status of the first activity to in progress
	SELECT a.UDCID AS StatusID, a.*
	FROM secuser.UserDefinedCode AS a
	WHERE a.UDCUDCGID = 16 
		AND a.UDCCode = 'IN'

	--Get the transactional process workflow
	SELECT * FROM SecUser.ProcessWF a
	WHERE a.ProcessReqTypeNo = @reqTypeNo
		AND a.ProcessReqType = @reqType

	SELECT @transProcessID = a.ProcessID 
	FROM SecUser.ProcessWF a
	WHERE a.ProcessReqTypeNo = @reqTypeNo
		AND a.ProcessReqType = @reqType

	-- Retrieve all parameters
	SELECT b.ReqTypeID, a.ParamName, a.ParamKey, a.ParamRet, a.ParamDataType, a.ParamDefault, a.ParamSeq,
		ISNULL(c.ReqParamTableName, '') AS ReqParamTableName,
		ISNULL(c.ReqParamColumnName, '') AS ReqParamColumnName
	FROM SecUser.GenPurposeProcessParameter AS a INNER JOIN
		SecUser.RequestType AS b ON a.ParamProcessID = b.ReqTypeProcessID LEFT JOIN
		SecUser.RequestTypeParameter AS c ON b.ReqTypeID = c.ReqParamReqTypeID AND a.ParamID = c.ReqParamParamID
	WHERE b.ReqTypeID = @reqTypeID
	ORDER BY a.ParamKey DESC, a.ParamSeq

	--Retrieve all transaction workflow activities
	SELECT * FROM SecUser.TransActivity AS a
	WHERE a.ActProcessID = @transProcessID
	ORDER BY a.ActSeq

	--Get the current WF activity of an open PAF - Acting requisition
	EXEC pr_GetTransactionActivity 1, @reqType, @reqTypeNo, 1, ''

	SELECT * FROM secuser.PAFWF a
	WHERE a.PAFNo = 67



	


	

	

