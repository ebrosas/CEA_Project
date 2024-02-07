using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    public class RequisitionStatus
    {
        #region Properties
        [Key]
        public decimal requisitionID { get; set; }

        [Display (Name = "Approval Role")]
        public string? approvalGroup { get; set; }

        [Display(Name = "Approver")]
        public string? approverEmpName { get; set; }

        [Display(Name = "Position")]
        public string? approverPosition { get; set; }

        [Display(Name = "Leave Status")]
        public string? leaveStatus { get; set; }

        [Display(Name = "Current Status")]
        public string? currentStatus { get; set; }

        public string? statusCode { get; set; }

        [Display(Name = "Approved Date")]
        public DateTime? approvedDate { get; set; }

        [Display(Name = "Approval Comments")]
        public string? approverComment { get; set; }

        public string? costCenter { get; set; }
        public string? costCenterName { get; set; }
        public DateTime? submittedDate { get; set; }
        public string? createBy { get; set; }
        public decimal? substituteEmpNo { get; set; }
        public string? substituteEmpName { get; set; }

        [Display(Name ="Approval Sequence")]
        public int groupRountingSequence { get; set; }
        public int routingSequence { get; set; }
        //public string? statusHandlingCode { get; set; }
        //public string? statusHandlingDesc { get; set; }
        #endregion

        #region Extended Properties
        [Display(Name = "Approver")]
        public string approverNameTitle
        {
            get
            {
                if (!string.IsNullOrEmpty(this.approverPosition))
                    return $"{this.approverEmpName}" + Environment.NewLine + $"{this.approverPosition}";
                else
                    return this.approverEmpName!;
            }
        }

        [Display(Name = "Substitute")]
        public string substituteFullName
        {
            get
            {
                if (this.substituteEmpNo > 0)
                    return $"{this.substituteEmpNo} - {this.substituteEmpName}";
                else
                    return string.Empty;
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
