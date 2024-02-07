/****************************************************************************************************************************************************************************************

Function Name					:	secuser.fnGetApproverEmail
Description						:	This UDF is used to get the email address of all approvers who have approved the CEA request
Created By						:	Ervin Brosas
Date Created					:	24 October 2023

Revision History:
	1.0					Ervin			2023.10.24 12:14 PM
	Created

*****************************************************************************************************************************************************************************************/

ALTER FUNCTION secuser.fnGetApproverEmail
(
    @ceaNo	INT 
)
RETURNS VARCHAR(1000)
AS
BEGIN	

	DECLARE	@empNo		INT = 0,
			@empEmail	VARCHAR(50) = '',
			@emailList	VARCHAR(1000) = ''

	DECLARE ApproverCursor CURSOR READ_ONLY FOR 
	SELECT a.AppCreatedBy AS EmpNo, b.EmpEmail
	FROM secuser.Approval a WITH (NOLOCK)
		INNER JOIN secuser.EmployeeMaster b ON a.AppCreatedBy = b.EmpNo
	WHERE a.AppApproved = 1
		AND a.AppReqTypeNo = @ceaNo

	--Open the cursor and fetch the data
	OPEN ApproverCursor
	FETCH NEXT FROM ApproverCursor
	INTO @empNo, @empEmail

	--Loop through each record to remove the NPH
	WHILE @@FETCH_STATUS = 0 
	BEGIN	

		IF LEN(@emailList) = 0
			SET @emailList = @empEmail
		ELSE
			SET @emailList = @emailList + ';' + @empEmail

		--Fetch next record
		FETCH NEXT FROM ApproverCursor
		INTO @empNo, @empEmail
	END 

	--Close and deallocate
	CLOSE ApproverCursor
	DEALLOCATE ApproverCursor

	RETURN RTRIM(ISNULL(@emailList, ''))

END 

/*	Debug:

	SELECT secuser.fnGetApproverEmail(20230128)

*/
