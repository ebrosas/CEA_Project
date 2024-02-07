using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    class ViewModelBase
    {
        #region Fields
        public enum ActionTypeOption
        {
            ReadOnly,
            EditMode,
            CreateNew,
            Approval,
            FetchEmployee
        }
        #endregion

        #region Properties
        public string? ErrorMessage { get; set; }
        public string? NotificationMessage { get; set; }

        [Display(Name = "Project No.")]
        public string? ProjectNo { get; set; }

        [Display(Name = "Requisition No.")]
        public string? RequisitionNo { get; set; }

        [Display(Name = "Cost Center")]
        public string CostCenter { get; set; } = null!;
        
        public string? CallerForm { get; set; }
        public string? PreviousCallerForm { get; set; }
        public int RequisitionID { get; set; }
        public string FormCode { get; set; } = null!;
        public string ActionType { get; set; } = null!;
        public string? QueryString { get; set; }
        public int? SearchEmpNo { get; set; }
        public string? SearchEmpName { get; set; }
        public byte? InvokeSearch { get; set; }
        public string? ToastNotification { get; set; }
        public string? JavascriptToRun { get; set; }
        public bool UseNewWF { get; set; }
        public byte? IgnoreSavedData { get; set; }        
        #endregion
    }
}
