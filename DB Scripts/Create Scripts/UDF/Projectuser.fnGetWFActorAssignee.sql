/**************************************************************************************************************************************************************
*	Revision History
*
*	Name: Projectuser.fnGetWFActorAssignee
*	Description: This function is used to fetch the currently assigned person of the specified workflow distribution group code
*
*	Date:			Author:		Rev.#:		Comments:
*	01/11/2023		Ervin		1.0			Created
**************************************************************************************************************************************************************/

ALTER FUNCTION Projectuser.fnGetWFActorAssignee
(
	@ceaNo			INT,
	@distListCode	VARCHAR(10)
)
RETURNS  @rtnTable TABLE  
(   
	EmpNo		        INT,
	EmpName				VARCHAR(50),
	Position			VARCHAR(50)
) 
AS
BEGIN
	
	--Get the distribution group assigned person
	INSERT INTO @rtnTable 
	SELECT d.ActionEmpNo, d.ActionEmpName, d.Position
	FROM Projectuser.sy_ProcessWF a WITH (NOLOCK)
		INNER JOIN Projectuser.sy_TransActivity b WITH (NOLOCK) ON a.ProcessID = b.ActProcessID
		INNER JOIN Projectuser.sy_ActivityAction c WITH (NOLOCK) ON b.ActID = c.ActionActID
		OUTER APPLY
		(
			SELECT TOP 1 y.CurrentDistMemEmpNo AS ActionEmpNo, y.CurrentDistMemEmpName AS ActionEmpName, RTRIM(z.Position) AS Position 
			FROM Projectuser.sy_Trans_DistributionMember x WITH (NOLOCK)
				INNER JOIN Projectuser.sy_CurrentDistributionMember y WITH (NOLOCK) ON x.DistMemID = y.CurrentDistMemRefID
				INNER JOIN Projectuser.Vw_MasterEmployeeJDE z WITH (NOLOCK) ON y.CurrentDistMemEmpNo = z.EmpNo
			WHERE x.DistMemPrimary = 1
				AND y.CurrentDistMemReqType = a.ProcessReqType
				AND y.CurrentDistMemReqTypeNo = a.ProcessReqTypeNo
				AND x.DistMemDistListID = c.ActionDistListID
			ORDER BY y.CurrentDistMemID DESC
		) d
	WHERE a.ProcessReqType = 22 
		AND a.ProcessReqTypeNo = @ceaNo
		AND RTRIM(b.ActCode) = @distListCode

	RETURN 

END


/*	Debugging:
	
	SELECT * FROM Projectuser.fnGetWFActorAssignee(20230137, 'APP_ORIG')			--Originator
	SELECT * FROM Projectuser.fnGetWFActorAssignee(20230137, 'APP_SUPERT')			--Superintendent

*/
