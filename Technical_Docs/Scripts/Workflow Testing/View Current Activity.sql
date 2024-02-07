DECLARE @reqType INT
DECLARE @reqTypeNo int
DECLARE @reqTypeID int

SELECT @reqType		= 22
SELECT @reqTypeNo	= 20230104    
SELECT @reqTypeID	= 78

/*
	BEGIN TRAN T1

	SELECT PAFAutoID, PAFEffectiveDate, PAFEmpNo, PAFEmpName, * FROM secuser.PAFWF WHERE PAFNo = 7206
	SELECT dbo.ConvertFromJulian(PAFEffectiveDate) as PAFEffectiveDate, * FROM secuser.PAFWF WHERE PAFEmpNo = 10003520
	SELECT * FROM [secuser].[History] WHERE HistReqNo = 4194 AND HistReqType = 11 ORDER BY HistCreatedDate DESC

	UPDATE SecUser.TransActivity SET ActCurrent = 1, ActStatusID = 107 WHERE ActID = 3945673
	UPDATE secuser.TransActivity SET ActCurrent = 0, ActStatusID = 109 WHERE ActID IN (4907886)	
	UPDATE secuser.TransActivity SET ActCurrent = 0, ActStatusID = 106 WHERE ActID BETWEEN 3945674 AND 3945678		
	UPDATE secuser.TransActivity SET ActCurrent = 0, ActStatusID = 108 WHERE ActID IN (4907893)	
	

	UPDATE secuser.TransActivity SET ActCurrent = 1 WHERE ActID = 497973

	UPDATE SecUser.TransActivity SET ActCurrent = 0, ActStatusID = 109 WHERE ActID = 907033

	UPDATE secuser.TransActivity SET ActStatusID = 109 WHERE ActID IN (907033,907034)

	(SELECT b.ActID
		FROM SecUser.ProcessWF AS a INNER JOIN
			SecUser.TransActivity AS b ON a.ProcessID = b.ActProcessID
		WHERE a.ProcessReqType = @reqType AND a.ProcessReqTypeNo = @reqTypeNo AND b.ActSeq = 1)

	UPDATE SecUser.TransActivity SET ActNextCode = 'UPDATE_TAS'
		WHERE ActID = 844

	SELECT c.LeaveNo, d.UDCSpecialHandlingCode
		FROM SecUser.ProcessWF AS a INNER JOIN
			SecUser.TransActivity AS b ON a.ProcessID = b.ActProcessID INNER JOIN
			SecUser.LeaveRequisitionWF AS c ON a.ProcessReqTypeNo = c.LeaveNo INNER JOIN
			SecUser.UserDefinedCode AS d ON c.LeaveReqStatusID = d.UDCID
		WHERE a.ProcessReqType = @reqType AND b.ActNextCode LIKE '%PAY%' AND d.UDCSpecialHandlingCode = 'Open'--a.ProcessReqTypeNo = @reqTypeNo
		ORDER BY b.ActSeq

	COMMIT TRAN T1
*/

	--Get workflow details
	SELECT a.CEARejectionRemarks, a.CEARejectEmailGroup, b.UDCID AS StatusID, b.UDCCode AS StatusCode, b.UDCDesc1 AS StatusDesc, b.UDCSpecialHandlingCode AS StatusHandlingCOde, a.* 
	FROM secuser.CEAWF a WITH (NOLOCK)
		INNER JOIN secuser.UserDefinedCode b WITH (NOLOCK) ON a.CEAStatusID = b.UDCID
	WHERE a.CEARequisitionNo = @reqTypeNo
	/*	Update the status
		BEGIN TRAN T1

		UPDATE secuser.CEAWF
		SET CEAStatusID = 131,
			CEAStatusCode = '123',
			CEAStatusHandlingCode = 'Closed'
		WHERE CEARequisitionNo = 20230087

		COMMIT TRAN T1
	*/

	SELECT b.*
		FROM SecUser.ProcessWF AS a INNER JOIN
			SecUser.TransActivity AS b ON a.ProcessID = b.ActProcessID
		WHERE a.ProcessReqType = @reqType AND a.ProcessReqTypeNo = @reqTypeNo
		ORDER BY b.ActSeq

	SELECT b.*
		FROM SecUser.ProcessWF AS a INNER JOIN
			SecUser.TransParameter AS b ON a.ProcessID = b.ParamProcessID
		WHERE a.ProcessReqType = @reqType AND a.ProcessReqTypeNo = @reqTypeNo
		ORDER BY b.ParamSeq

	SELECT a.*, b.DistMemDistListID, DistMemStatusID, DistMemID
		FROM SecUser.CurrentDistributionMember AS a INNER JOIN
			SecUser.DistributionMember AS b ON a.CurrentDistMemRefID = b.DistMemID
		WHERE a.CurrentDistMemReqType = @reqType AND a.CurrentDistMemReqTypeNo = @reqTypeNo
		ORDER BY a.CurrentDistMemModifiedDate

	SELECT * FROM secuser.History a WITH (NOLOCK)
	WHERE a.HistReqNo = @reqTypeNo
		AND a.HistReqType = @reqType
	ORDER BY a.HistCreatedDate DESC

	SELECT * FROM secuser.Approval a WITH (NOLOCK)
	WHERE a.AppReqTypeNo = @reqTypeNo
		AND a.AppReqType = @reqType
	ORDER BY a.AppCreatedDate DESC

/*	Debugging:

	BEGIN TRAN T1

	--Correct the workflow re-assignment back to previous approver
	SELECT * FROM SecUser.CurrentDistributionMember WHERE CurrentDistMemRefID = 622874
	SELECT * FROM SecUser.DistributionMember WHERE DistMemID = 622874
	SELECT * FROM SecUser.DistributionMember WHERE DistMemDistListID = 381789 order by DistMemRoutineSeq
	SELECT * FROM secuser.History WHERE HistReqNo = 4195 AND HistReqType = 11 ORDER BY HistCreatedDate DESC

	UPDATE SecUser.CurrentDistributionMember SET CurrentDistMemCurrent = 0, CurrentDistMemStatusID = 63 WHERE CurrentDistMemID = 404739

	UPDATE SecUser.DistributionMember SET DistMemStatusID = 109 WHERE DistMemID = 2225762
	UPDATE SecUser.DistributionMember SET DistMemCurrent = 0 WHERE DistMemID in (757276, 793321)
	
	DELETE FROM [secuser].[History] 
	WHERE HistReqNo = 28218 
		AND HistReqType = 7 
		AND HistCreatedDate IN ('2022-09-22 09:05:25.367', '2022-09-22 10:22:34.843')

	--Set the current assigned person
	EXEC secuser.pr_SetCurrentDistributionMember 11, 4697, 64, 381789, 3, 10001707, 0
	@reqType int,
	@reqTypeNo int,
	@actionType int,
	@distMemDistListID int,
	@distMemRoutineSeq int,
	@createdModifiedBy int,
	@retError int output
			
	
	UPDATE SecUser.CurrentDistributionMember SET CurrentDistMemCurrent = 0 WHERE CurrentDistMemID = 404691
	UPDATE SecUser.CurrentDistributionMember SET CurrentDistMemEmpNo = 10001430, CurrentDistMemEmpName = 'A.RAZZAQ MOHAMED AMIN', CurrentDistMemEmpEmail = 'arazzaq.ameen@garmco.com' WHERE CurrentDistMemID = 139781
	UPDATE SecUser.CurrentDistributionMember SET CurrentDistMemCurrent = 1, CurrentDistMemActionType = 151 WHERE CurrentDistMemID IN (87020)
	UPDATE SecUser.CurrentDistributionMember SET CurrentDistMemEmpNo = 10003838, CurrentDistMemEmpName = 'MOHAMED MUSTAFA MOHAMED RAFEA', CurrentDistMemEmpEmail = 'cro@garmco.com' WHERE CurrentDistMemID = 492778

	COMMIT TRAN T1

	SELECT * FROM SecUser.CurrentDistributionMember WHERE CurrentDistMemReqTypeNo = 4043 AND CurrentDistMemReqType = 11
	SELECT * FROM SecUser.DistributionMember WHERE DistMemDistListID = 347381 order by DistMemRoutineSeq
	SELECT * FROM [secuser].[History] WHERE HistReqNo = 4030 AND HistReqType = 11 ORDER BY HistCreatedDate DESC

	select * from SecUser.UserDefinedCode where UDCCode in ('05', '120')
	select * from SecUser.UserDefinedCode  where UDCUDCGID = 9 and UDCSpecialHandlingCode = 'Open'
	select * from SecUser.UserDefinedCode  where UDCUDCGID = 9 and UDCSpecialHandlingCode = 'Rejected'
	select * from SecUser.UserDefinedCode  where UDCUDCGID = 9 and UDCSpecialHandlingCode = 'Approved'
	select * from SecUser.UserDefinedCode  where UDCUDCGID = 9 and UDCSpecialHandlingCode = 'Validated'
	select * from SecUser.UserDefinedCode  where UDCUDCGID = 9 and UDCSpecialHandlingCode = 'Closed'
	select * from SecUser.UserDefinedCode  where UDCUDCGID = 9 and UDCSpecialHandlingCode = 'Cancelled'
	select * from SecUser.UserDefinedCode where UDCID in (46, 63)

*/

/*	Update the current assigned person
	
	select * from secuser.EPAWF
	where EPAReqStatusCode = '05'
	and convert(int, EPAPayGrade) >= 12 

	DECLARE @reqType int, @reqTypeNo int
	SELECT @reqType		= 11			--(Note: 7 => PAF; 11 => EPA)
	SELECT @reqTypeNo	= 4697  

	SELECT a.*
	FROM SecUser.DistributionMember a 
		INNER JOIN SecUser.CurrentDistributionMember b ON a.DistMemID = b.CurrentDistMemRefID
	WHERE b.CurrentDistMemReqType = @reqType AND b.CurrentDistMemReqTypeNo = @reqTypeNo

	BEGIN TRAN T1

	SELECT * FROM SecUser.DistributionMember 
	WHERE DistMemID = 912213

	UPDATE SecUser.DistributionMember 
	SET DistMemEmpNo = 10001668,
		DistMemEmpName = 'EBRAHIM KHALIL EBRAHIM',
		DistMemEmpEmail = 'ebrahim.khalil@garmco.com'
	WHERE DistMemID = 912213

	UPDATE SecUser.CurrentDistributionMember 
	SET CurrentDistMemEmpNo = 10001668,
		CurrentDistMemEmpName = 'EBRAHIM KHALIL EBRAHIM',
		CurrentDistMemEmpEmail = 'ebrahim.khalil@garmco.com'
	WHERE CurrentDistMemID = 179717

	UPDATE SecUser.DistributionMember 
	SET DistMemStatusID = 106	--(Note: 109 => completed, 107 => In Progress)
	WHERE DistMemID = 2822043

	UPDATE SecUser.CurrentDistributionMember 
	SET CurrentDistMemCurrent = 1,
		CurrentDistMemStatusID = 46	--(Note: 150 => Reviewed by Validator; 149 => For Validation; 46 => Waiting For Approval; 63 => Approved by Approver) 
	WHERE CurrentDistMemID = 497866

	UPDATE SecUser.DistributionMember 
	SET DistMemStatusID = 109	--(Note: 109 => completed, 107 => In Progress, 106 => Pending)
	WHERE DistMemID IN (3820785)

	UPDATE SecUser.DistributionMember 
	SET DistMemStatusID = 106	--(Note: 109 => completed, 107 => In Progress, 106 => Pending)
	WHERE DistMemID = 1766692	

	UPDATE SecUser.CurrentDistributionMember 
	SET CurrentDistMemCurrent = 0
	WHERE CurrentDistMemID = 607165		

	DELETE SecUser.CurrentDistributionMember WHERE CurrentDistMemID IN (502904)

	--Set RequestStatusID
	UPDATE SecUser.TransParameter
	SET ParamValue = '58'	--(Note: 63 = Approved By Approver; 46 = Waiting for Approval; 113 = Request Sent)
	WHERE ParamID = 6913244		

	--Set RequestStatusCode
	UPDATE SecUser.TransParameter
	SET ParamValue = '110'	--(Note: 120 = Approved By Approver; 05 = Waiting for Approval; 02 = Request Sent)
	WHERE ParamID = 6913245

	DELETE FROM  SecUser.CurrentDistributionMember 
	WHERE CurrentDistMemID = 497863		

	SELECT * FROM secuser.History WHERE HistReqNo = 8045 ORDER BY HistCreatedDate DESC
	SELECT * FROM secuser.History WHERE HistReqNo = 8045 AND HistCreatedBy = 10003636 ORDER BY HistCreatedDate DESC

	DELETE FROM secuser.History WHERE HistReqNo = 8045 AND HistCreatedBy = 10003636

	SELECT * FROM secuser.Approval WHERE AppReqTypeNo = 8045

	DELETE FROM secuser.Approval WHERE AppReqTypeNo = 8045 AND AppActID = 1107324

	COMMIT TRAN T1
	ROLLBACK TRAN T1

*/

/*	Update Routine History

	select * from SecUser.UserDefinedCode where UDCCode in ('02', '120', '101', '130') AND UDCUDCGID = 9
	select * from SecUser.UserDefinedCode  where UDCUDCGID = 9 and UDCSpecialHandlingCode = 'Open'
	select * from SecUser.UserDefinedCode  where UDCUDCGID = 9 and UDCSpecialHandlingCode = 'Rejected'
	select * from SecUser.UserDefinedCode  where UDCUDCGID = 9 and UDCSpecialHandlingCode = 'Approved'
	select * from SecUser.UserDefinedCode  where UDCUDCGID = 9 and UDCSpecialHandlingCode = 'Validated'
	select * from SecUser.UserDefinedCode  where UDCUDCGID = 9 and UDCSpecialHandlingCode = 'Cancelled'

	SELECT * FROM [secuser].[History] WHERE HistReqNo = 4675 AND HistReqType = 11 ORDER BY HistCreatedDate DESC
	
	BEGIN TRAN T1

	UPDATE [secuser].[History] 
	SET HistCreatedName = 'EBRAHIM KHALIL EBRAHIM',
		HistDesc = 'Open - Waiting For Approval (EBRAHIM KHALIL EBRAHIM)' 
	WHERE HistReqNo = 4675  
		AND HistReqType = 11 
		AND HistCreatedDate = '2014-10-11 13:58:12.827' 
		AND HistCreatedBy = 10001645

	DELETE FROM [secuser].[History] WHERE HistReqNo = 4016 AND HistReqType = 11 AND HistCreatedDate = '2014-04-13 08:00:06.900' AND HistCreatedBy = 10001206
	

	COMMIT TRAN T1
	ROLLBACK TRAN T1

*/