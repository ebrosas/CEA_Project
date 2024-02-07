using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    public class ErrorViewModel
    {
        #region Properties
        public string? RequestId { get; set; }
         
        public bool ShowRequestId => !string.IsNullOrEmpty(RequestId);

        [Display(Name = "Requested Action")]
        public string? ActionName { get; set; }

        [Display(Name = "Offending URL")]
        public string? OffendingURL { get; set; }

        [Display(Name = "Source")]
        public string? Source { get; set; }

        [Display(Name = "Message")]
        public string? Message { get; set; }

        [Display(Name = "Inner Message")]
        public string? InnerMessage { get; set; }

        [Display(Name = "Stack Trace")]
        public string? StackTrace { get; set; }

        public int? ErrorCode { get; set; }
        public string? CallerForm { get; set; }        
        #endregion
    }
}