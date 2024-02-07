using CEAApp.Web.Models;
using static CEAApp.Web.Repositories.ProjectRepository;

namespace CEAApp.Web.Repositories
{
    public interface IProjectRepository
    {
        ReferenceData LookupData { get; set; }
        Task<ReferenceData> GetLookupTable(string objectCode = "");
        List<ProjectDetail> GetProjectList(int fiscalYear = 0, string projectNo = "", string costCenter = "", string expenditureType = "", string statusCode = "", string keywords = "");
        ProjectInfo GetProjectDetail(string projectNo);
        List<RequisitionDetail> GetRequisitionList(string projectNo = "", string requisitionNo = "", string expenditureType = "", int fiscalYear = 0, string statusCode = "", string costCenter = "", 
            int empNo = 0, string approvalType = "", string keywords = "", DateTime? startDate = null, DateTime? endDate = null);
        Task<List<RequisitionDetail>> GetRequisitionListNew(string projectNo = "", string requisitionNo = "", string expenditureType = "", int fiscalYear = 0, string statusCode = "",
            string costCenter = "", int empNo = 0, string approvalType = "", string keywords = "", DateTime? startDate = null, DateTime? endDate = null, byte createdByType = 0);
        Task<DBTransResult> InsertUpdateDeleteProject(DataAccessType actionType, ProjectInfo project);
        List<EmployeeInfo> GetEmployeeList(int empNo = 0);
        Task<List<RequisitionStatus>> GetRequisitionStatus(int requisitionID);
        Task<List<ExpenseDetail>> GetExpenseList(string requisitionNo);
        EmployeeDetail GetEmployeeInfo(string userID);
        EmployeeInfo GetEmployeeByDomainName(string loginName, string ldapPath, string ldapUsername, string ldapPassword);
        List<EmployeeDetail> SearchEmployee(int? empNo, string? empName, string? costCenter);
        CEARequest? GetRequisitionDetail(string requisitionNo);
        FormAccessEntity? GetUserFormAccess(string userFrmFormCode, string userFrmCostCenter, int userFrmEmpNo, byte mode = 1, int userFrmFormAppID = 1, string userFrmEmpName = "", string sort = "");
        List<Equipment> GetEquipmentList(string equipmentNo = "", string equipmentDesc = "");
        Task<DBTransResult?> ChangeRequisitionStatus(string requisitionNo, string actionType, int empNo, string comments, string cancelledByName, string wfInstanceID);
        Task<DBTransResult?> InsertUpdateDeleteRequisition(DataAccessType dbAccessType, CEARequest requestData);
        Task<DBTransResult?> RunWorkflowProcess(string ceaNo, int userEmpNo, string userEmpName, string userID);
        Task<DBTransResult?> ApproveRejectRequest(string requisitionNo, string wfInstanceID, int appRole, int appRoutineSeq, bool appApproved, string appRemarks, int approvedBy, string approvedName, string statusCode);
        Task<List<WFApprovalStatus>> GetWorkflowStatus(string ceaNo);
        Task<DBTransResult?> ReassignRequest(string requisitionNo, int currentAssignedEmpNo, int reassignedEmpNo, string reassignedEmpName, string reassignedEmpEmail, 
            int routineSeq, bool onHold, string reason, int reassignedBy, string reassignedName, string wfInstanceID, string ceaDescription);
    }
}
