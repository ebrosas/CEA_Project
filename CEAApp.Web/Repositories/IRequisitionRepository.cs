using CEAApp.Web.Models;
namespace CEAApp.Web.Repositories
{
    public interface IRequisitionRepository
    {
        ReferenceData LookupData { get; set; }
        Task<ReferenceData> GetLookupTable();
        Task<List<Requisition>> LoadRequisitionAsync(string costCenter, string expenditureType, int? fiscalYear, string projectNo, string requisitionStatus, int requisitionNo, string keywords,
             bool filterToUser, int employeeNo);

        Task<List<Requisition>> LoadRequisitionAssignmentAsync(string CostCenter, string ExpenditureType, string ProjectNo, int RequisitionNo, int FromFiscalYear, int ToFiscalYear);

        Task<List<Requisition>> LoadEquipmentNoAsync(string RequisitionNo);

        Task<DBTransResult?> SaveEquipmentNoAsync(string RequisitionNo, string EquipmentNo, string ParentEquipmentNo, string IsEquipmentNoRequired);
        
        Task<Int32> UploadToOneWorld(int requisitionID, int companyCode, string costCenter, string objectCode, string subjectCode, string accountCode, string requisitionAmount, string userID, string workstationID);

        Task<bool> UpdateRequisitionStatus(string statusCode,int requisitionID, string employeeNo, string approverComment);

        Task<bool> CloseRequisitionUpdationToOneWorld(int requisitionID);

        Task<List<ApproversDetails>> LoadApproversDetailsAsync(int requisitionID);

        List<RequisitionDetail> GetAssignedRequisitionList(int requisitionNo, string expenditureType,int fromFiscalYear, int toFiscalYear, string costCenter, int empNo);

        Task<DBTransResult> ReassignmentRequisition(List<string> selectedRequisition, int? UserEmpNo, string userEmpName, string userID, string ApproverRemarks, int ReassignEmpNo, string newApproverName, 
                string newApproverEmail, int CreatedBy,int routineSeq, bool onHold);

    }
}
