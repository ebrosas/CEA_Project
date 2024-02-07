using CEAApp.Web.Models;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace CEAApp.Web.ViewModels
{
    public class ReassignmentVM 
    {
        #region Fields
        public string ErrorMessage { get; set; }
        public string NotificationMessage { get; set; }
        public string FiscalYear { get; set; }
        public string CostCenter { get; set; }
        public string ProjectStatus { get; set; }
        public string ExpenditureType { get; set; }
        public string RequisitionStatus { get; set; }
        public string FormCode { get; set; } = null!;
        public Reassignment Reassignment = new Reassignment();
        public bool disableElements { get; set; }

        public List<SelectListItem> FiscalYearList { get; set; }
        public List<SelectListItem> CostCenterList { get; set; }
        public List<SelectListItem> ProjectStatusList { get; set; }
        public List<SelectListItem> ExpenditureTypeList { get; set; }
        public List<SelectListItem> RequisitionStatusList { get; set; }
        #endregion

        #region Methods

        #endregion
    }
}
