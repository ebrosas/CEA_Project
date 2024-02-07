namespace CEAApp.Web.ViewModels
{
    public class RequisitionSearchVM
    {
        public int fiscalYear { get; set; }
        public string requisitionStatus { get; set; }
        public string projectStatus { get; set; }
        public string costCenter { get; set; }
        public string expenditureType { get; set; }
        public string projectNo { get; set; }
        public string requisitionNo { get; set; }
        public bool filterMyPendingApprovals { get; set; }
        public string originatorName { get; set; }
        public int originatorEmployeeNo { get; set; }
        public string currentApproverName { get; set; }
        public int currentApproverEmployeeNo { get; set; }
        public int requisitionAssignedToEmployeeNo { get; set; }
        public bool reassignApprover { get; set; }
        public bool reassignApproverOnLeave { get; set; }
        public string requisitionDescription { get; set; }
        public string requisitionStatusDescription { get; set; }
        public string searchProjectNo { get; set; }
        public string searchRequisitionNo { get; set; }
        public string projectAccountNo { get; set; }
    }
}
