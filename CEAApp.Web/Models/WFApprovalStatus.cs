using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    public class WFApprovalStatus
    {
        #region Properties        
        [Key]
        public int activityID { get; set; }

        [Display(Name = "Approval Role")]
        public string? approvalRole { get; set; }

        [Display(Name = "Approver")]
        public string? approver { get; set; }
                

        [Display(Name = "Current Status")]
        public string? currentStatus { get; set; }

        [Display(Name = "Approved Date")]
        public DateTime? approvedDate { get; set; }

        [Display(Name = "Comments")]
        public string? approverRemarks { get; set; }
        
        public string? activityCode { get; set; }
        public int activitySequence { get; set; }

        public string? projectNo { get; set; }
        public string? projectType { get; set; }
        public string? approverPosition { get; set; }
        #endregion

        #region Extended Properties
        [Display(Name = "Approver")]
        public string approverNameTitle
        {
            get
            {
                if (!string.IsNullOrEmpty(this.approverPosition))
                    return $"{this.approver}" + Environment.NewLine + $"{this.approverPosition}";
                else
                    return this.approver!;
            }
        }

        public string approvedDateStr
        {
            get
            {
                bool isDate = false;
                DateTime dateVal = DateTime.Now;
                if (this.approvedDate != null && DateTime.TryParse(this.approvedDate.ToString(), out dateVal))
                    isDate = true;

                if (isDate)
                    return dateVal.Date.ToString("dd-MMM-yyyy");
                else
                    return string.Empty;
            }
        }
        #endregion
    }
}
