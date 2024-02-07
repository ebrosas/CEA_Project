using CEAApp.Web.Models;
using Microsoft.AspNetCore.Mvc.Rendering;

namespace CEAApp.Web.ViewModels
{
    class RequisitionVM : ViewModelBase
    {
        #region Fields
        public string? ErrorMessage { get; set; }
        public string? NotificationMessage { get; set; }
        public string FiscalYear { get; set; }
        public string CostCenter { get; set; }
        public string ProjectStatus { get; set; }
        public string ExpenditureType { get; set; }
        public string RequisitionStatus { get; set; }
        public string? ToastNotification { get; set; }
        public Requisition requisition = new Requisition();
        public bool disableElements { get; set; }

        public List<SelectListItem> FiscalYearArray { get; set; }
        public List<SelectListItem> CostCenterArray { get; set; }
        public List<SelectListItem> ProjectStatusArray { get; set; }
        public List<SelectListItem> ExpenditureTypeArray { get; set; }
        public List<SelectListItem> RequisitionStatusArray { get; set; }
        #endregion
     
        #region Methods

        #endregion
    }
}
