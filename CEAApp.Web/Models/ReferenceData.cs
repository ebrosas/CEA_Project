using Microsoft.AspNetCore.Mvc.Rendering;

namespace CEAApp.Web.Models
{
    [Serializable]
    public class ReferenceData
    {
        #region Properties
        public List<UserdefinedCode>? FiscalYearList { get; set; }
        public List<UserdefinedCode>? CostCenterList { get; set; }
        public List<UserdefinedCode>? ProjectStatusList { get; set; }
        public List<UserdefinedCode>? ExpenditureTypeList { get; set; }
        public List<UserdefinedCode>? ExpenseTypeList { get; set; }
        public List<UserdefinedCode>? RequisitionStatusList { get; set; }
        public List<UserdefinedCode>? ApprovalTypeList { get; set; }
        public List<UserdefinedCode>? ItemTypeList { get; set; }
        public List<UserdefinedCode>? PlantLocationList { get; set; }
        public List<UserdefinedCode>? ExpenseYearList { get; set; }
        public List<UserdefinedCode>? ExpenseQuarterList { get; set; }
        public List<EmployeeDetail>? CEAAdminList { get; set; }
        #endregion
    }
}
