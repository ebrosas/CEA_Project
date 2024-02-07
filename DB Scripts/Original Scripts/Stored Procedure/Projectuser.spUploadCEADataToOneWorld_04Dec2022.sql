USE [ProjectRequisition]
GO
/****** Object:  StoredProcedure [Projectuser].[spUploadCEADataToOneWorld]    Script Date: 04/12/2022 12:04:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












/***********************************************************************************************************
Procedure Name 	: spUploadCEADataToOneWorld
Purpose		: This SP will upload requisition data to OneWorld system

Author		: Zaharan Haleed
Date		: 09 May 2007
------------------------------------------------------------------------------------------------------------
Modification History:
	1.

************************************************************************************************************/
ALTER                  Procedure [Projectuser].[spUploadCEADataToOneWorld] 
	( 	@RequisitionID		as Int,			-- CEA/MRE Requisition Id
		@CompanyID		as varchar(5),		-- Company ID
		@CostCenter		as varchar(12),		-- Cost Center
		@UserID			as varchar(10),		-- User ID
		@WorkStationID		as varchar(10),		-- Workstation ID of the user
		@ObjectAccount		as varchar(6),		-- Cbject Code
		@SubjectAccount		as varchar(8), 		-- Subject Code
		@AccountCode		as varchar(10),		-- Account Code
		@RequisitionAmount	as numeric(18,3) )	-- CEA/MRE Requisition value
As

Declare @Century 		as int
Declare @LedgerType		as varchar(2)
Declare @SubLedgerType		as char(1)
Declare @ZeroValue		as int
Declare @AccountID		as varchar(8)
Declare @BlankSpace		As varchar(5)
Declare @SubLedger		as varchar(8)
Declare @FiscalYear		as int
Declare @RequisitionNo 		as varchar(8)
Declare @AccCostCenter		as varchar(12)
Declare @ProjectNo		as varchar(12)
Declare @ProjectAccNo		as varchar(20)
Declare @ShortDescription	as varchar(40)

--Default values
Set @Century 		= 20
Set @LedgerType		= 'BA'
Set @ZeroValue		= 0
Set @BlankSpace		= ''
Set @SubLedgerType	= 'A'

Select  distinct top 1 @CompanyID = MCCO from Projectuser.Master_CostCenter where CostCenter = @CostCenter

Select @RequisitionNo = RequisitionNo, @ShortDescription = RequisitionDescription 
	From Requisition Where RequisitionID = @RequisitionID
Select @ProjectNo = ProjectNo From Requisition Where RequisitionID = @RequisitionID

select @ProjectAccNo = Projectuser.AccountNo(@ProjectNo)

set @AccCostCenter = (select substring(@ProjectAccNo,1,charindex('.',@ProjectAccNo) -1))
set @AccCostCenter = rtrim(ltrim(@AccCostCenter))
set @AccCostCenter = Projectuser.lpad(@AccCostCenter,12,' ')

Set @RequisitionAmount = @RequisitionAmount * 1000

if @SubjectAccount = '&nbsp;'
	Set @SubjectAccount = ''

--Find the AccountID
select distinct @AccountID = AccountID From Project
	where AccountCode = @AccountCode 
	And subjectcode = @SubjectAccount
	And objectcode = @ObjectAccount 

--Format the Requisition No with preceding 0 in case its length is less than 8
Set @SubLedger = Projectuser.lpad (@RequisitionNo,8,'0')

--Get the project year
select @FiscalYear = p.FiscalYear from project p 
	inner join requisition r on p.projectno = r.projectno
where r.requisitionid = @RequisitionID
--Get the 2digit year part
select @FiscalYear = convert(int,substring(convert(varchar,year(getdate())), 3,4),00)

--------------------------------------------------------------------------------
--Insert data into the F0902 table
----------------------------------
INSERT INTO JDE_PRODUCTION.PRODDTA.F0902 (
	GBAID, 		-- AccountID			1
	GBCTRY, 	-- Century			2
	GBFY, 		-- FiscalYear1			3
	GBFQ, 		-- FiscalQtrFutureUse		4
	GBLT, 		-- LedgerType			5
	GBSBL, 		-- Subledger			6
	GBCO, 		-- Company			7
	GBAPYC, 	-- AmtBeginningBalancePy	8
	GBAN01, 	-- AmountNetPosting001		9
	GBAN02, 	-- AmountNetPosting002		10
	GBAN03, 	-- AmountNetPosting003		11
	GBAN04, 	-- AmountNetPosting004		12
	GBAN05, 	-- AmountNetPosting005		13
	GBAN06, 	-- AmountNetPosting006		14
	GBAN07, 	-- AmountNetPosting007		15
	GBAN08, 	-- AmountNetPosting008		16
	GBAN09, 	-- AmountNetPosting009		17
	GBAN10, 	-- AmountNetPosting010		18
	GBAN11, 	-- AmountNetPosting011		19
	GBAN12, 	-- AmountNetPosting012		20
	GBAN13, 	-- AmountNetPosting013		21
	GBAN14, 	-- AmountNetPosting014		22
	GBAPYN, 	-- AmtPriorYrNetPosti		23
	GBAWTD, 	-- AmountWtd			24
	GBBORG, 	-- AmtOriginalBeginBud		25
	GBPOU, 		-- AmtProtectedOverUnder	26
	GBPC, 		-- PercentComplete		27
	GBTKER,		-- UnitsProjectedFinal		28
	GBBREQ, 	-- BudgetRequested		29
	GBBAPR, 	-- BudgetApproved		30
	GBMCU, 		-- CostCenter			31
	GBOBJ, 		-- ObjectAccount		32
	GBSUB, 		-- Subsidiary			33
	GBUSER, 	-- UserId			34
	GBPID, 		-- ProgramId			35
	GBUPMJ, 	-- DateUpdated			36
	GBJOBN, 	-- WorkStationId		37
	GBSBLT, 	-- subledgerType		38
	GBUPMT, 	-- TimeLastUpdated		39
	GBCRCD, 	-- CurrencyCodeFrom		40
	GBCRCX		-- CurrencyCodeDenom		41 
)
VALUES
(
	@AccountID, 				-- AccountID			1
	@Century, 				-- Century			2
	@FiscalYear, 				-- FiscalYear1			3
	@BlankSpace, 				-- FiscalQtrFutureUse		4
	@LedgerType, 				-- LedgerType			5
	@SubLedger,				-- Subledger			6
	@CompanyID, 				-- Company			7
	@ZeroValue, 				-- AmtBeginningBalancePy	8
	@RequisitionAmount, 			-- AmountNetPosting001		9
	@ZeroValue, 				-- AmountNetPosting002		10
	@ZeroValue, 				-- AmountNetPosting003		11
	@ZeroValue, 				-- AmountNetPosting004		12
	@ZeroValue, 				-- AmountNetPosting005		13
	@ZeroValue, 				-- AmountNetPosting006		14
	@ZeroValue, 				-- AmountNetPosting007		15
	@ZeroValue, 				-- AmountNetPosting008		16
	@ZeroValue, 				-- AmountNetPosting009		17
	@ZeroValue, 				-- AmountNetPosting010		18
	@ZeroValue, 				-- AmountNetPosting011		19
	@ZeroValue, 				-- AmountNetPosting012		20
	@ZeroValue, 				-- AmountNetPosting013		21
	@ZeroValue, 				-- AmountNetPosting014		22
	@ZeroValue, 				-- AmtPriorYrNetPosti		23
	@ZeroValue, 				-- AmountWtd			24
	@ZeroValue, 				-- AmtOriginalBeginBud		25
	@ZeroValue, 				-- AmtProtectedOverUnder	26
	@ZeroValue, 				-- PercentComplete		27
	@ZeroValue,				-- UnitsProjectedFinal		28
	@ZeroValue, 				-- BudgetRequested		29
	@ZeroValue, 				-- BudgetApproved		30
	@AccCostCenter,				-- CostCenter			31
	@ObjectAccount,	 			-- ObjectAccount		32
	@SubjectAccount,			-- Subsidiary			33
	@UserID, 				-- UserId			34
	@SubLedger, 				-- ProgramId			35
	Projectuser.ConvertToJulian(getdate()), -- DateUpdated			36
	@WorkStationID, 			-- WorkStationId		37
	@SubLedgerType,				-- subledgerType		38
	convert(int,Projectuser.fmtTime(getdate())),	-- TimeLastUpdated		39
	@BlankSpace, 				-- CurrencyCodeFrom		40
	@BlankSpace				-- CurrencyCodeDenom		41
)

--------------------------------------------------------------------------------
--Update the F0902 table
------------------------
UPDATE JDE_PRODUCTION.PRODDTA.F0101
SET	ABAT1 = 'J'			
WHERE ABAN8 = @RequisitionNo

--------------------------------------------------------------------------------
--Insert data into the F0111 table
----------------------------------
INSERT INTO JDE_PRODUCTION.PRODDTA.F0111 (
	WWAN8, 		-- AddressNumber		1
	WWIDLN, 	-- LineNumberID			2
	WWDSS5, 	-- SequenceNumber52Display	3
	WWMLNM, 	-- NameMailing			4
	WWATTL, 	-- ContactTitle			5
	WWREM1, 	-- Remark1			6
	WWSLNM,		-- SalutationName		7
	WWALPH,		-- NameAlpha			8
	WWDC,		-- DescrpCompressed		9
	WWGNNM,		-- NameGiven			10
	WWMDNM,		-- NameMiddle			11
	WWSRNM,		-- NameSurname			12
	WWTYC,		-- TypeCode			13
	WWW001,		-- CategoryCodeWhosWh001	14
	WWW002,		-- CategoryCodeWhosWh002	15
	WWW003,		-- CategoryCodeWhosWh003	16
	WWW004,		-- CategoryCodeWhosWh004	17
	WWW005,		-- CategoryCodeWhosWh005	18
	WWW006,		-- CategoryCodeWhosWh006	19
	WWW007,		-- CategoryCodeWhosWh007	20
	WWW008,		-- CategoryCodeWhosWh008	21
	WWW009,		-- CategoryCodeWhosWh009	22
	WWW010,		-- CategoryCodeWhosWh010	23
	WWMLN1,		-- SecondaryMailingName		24
	WWALP1,		-- Kanjualpha			25
	WWUSER,		-- UserID			26
	WWPID,		-- ProgramID			27
	WWUPMJ,		-- DateUpdated			28
	WWJOBN,		-- WorkStationID		29
	WWUPMT		-- TimeLastUpdated		30
)
VALUES
(
	@RequisitionNo, 		-- AddressNumber		1
	@ZeroValue, 			-- LineNumberID			2
	@ZeroValue, 			-- SequenceNumber52Display	3
	@ShortDescription, 		-- NameMailing			4
	@BlankSpace, 			-- ContactTitle			5
	@BlankSpace, 			-- Remark1			6
	@BlankSpace,			-- SalutationName		7
	@ShortDescription,		-- NameAlpha			8
	@ShortDescription,		-- DescrpCompressed		9
	@BlankSpace,			-- NameGiven			10
	@BlankSpace,			-- NameMiddle			11
	@BlankSpace,			-- NameSurname			12
	@BlankSpace,			-- TypeCode			13
	@BlankSpace,			-- CategoryCodeWhosWh001	14
	@BlankSpace,			-- CategoryCodeWhosWh002	15
	@BlankSpace,			-- CategoryCodeWhosWh003	16
	@BlankSpace,			-- CategoryCodeWhosWh004	17
	@BlankSpace,			-- CategoryCodeWhosWh005	18
	@BlankSpace,			-- CategoryCodeWhosWh006	19
	@BlankSpace,			-- CategoryCodeWhosWh007	20
	@BlankSpace,			-- CategoryCodeWhosWh008	21
	@BlankSpace,			-- CategoryCodeWhosWh009	22
	@BlankSpace,			-- CategoryCodeWhosWh010	23
	@BlankSpace,			-- SecondaryMailingName		24
	@BlankSpace,			-- Kanjualpha			25
	@UserID,			-- UserID			26
	@SubLedger,					-- ProgramID			27
	Projectuser.ConvertToJulian(getdate()),		-- DateUpdated			28
	@WorkStationID,					-- WorkStationID		29
	convert(int,Projectuser.fmtTime(getdate()))	-- TimeLastUpdated		30
)













