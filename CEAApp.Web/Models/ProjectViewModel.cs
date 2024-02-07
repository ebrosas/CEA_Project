using Microsoft.AspNetCore.Mvc.Rendering;

namespace CEAApp.Web.Models
{
    class ProjectViewModel : ViewModelBase
    {
        #region Properties        
        public string? FiscalYear { get; set; }        
        public string? ProjectStatus { get; set; }
        public string? ExpenditureType { get; set; }
        public string? RequisitionStatus { get; set; }
        public List<SelectListItem> FiscalYearArray { get; set; } = null!;
        public List<SelectListItem> CostCenterArray { get; set; } = null!;
        public List<SelectListItem> ProjectStatusArray { get; set; } = null!;
        public List<SelectListItem> ExpenditureTypeArray { get; set; } = null!;
        public List<SelectListItem> ExpenseTypeArray { get; set; } = null!;
        public List<SelectListItem> RequisitionStatusArray { get; set; } = null!;
        public List<SelectListItem> ApprovalTypeArray { get; set; } = null!;
        public ProjectInfo? ProjectDetail { get; set; }
        public List<RequisitionDetail> RequisitionList { get; set; } = null!;
        public SearchCriteria? SearchFilter { get; set; }        
        #endregion
    }
}
