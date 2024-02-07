using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    public class RequisitionDetail 
    {
        #region Properties
        [Key]
        public decimal requisitionID { get; set; }

        [Display(Name = "Project No.")]
        public string? projectNo { get; set; }

        [Display(Name = "Fiscal Year")]
        public int fiscalYear { get; set; }

        [Display(Name = "Requisition No.")]
        public string? requisitionNo { get; set; }

        [Display(Name = "Requisition Date"), DataType(DataType.Date)]
        public DateTime? requisitionDate { get; set; }

        [Display(Name ="Description")]
        public string? description { get; set; }

        [Display(Name = "Date of Commission"), DataType(DataType.Date)]
        public DateTime? dateofComission { get; set; }

        [Display(Name = "Amount"), DataType(DataType.Currency)]
        public decimal? amount { get; set; }

        [Display(Name = "Used Amount"), DataType(DataType.Currency)]
        public decimal? usedAmount { get; set; }

        [Display(Name = "Status")]
        public string? approvalStatus { get; set; }
        public string? statusCode { get; set; }

        public string? workflowStatus { get; set; }
        public string? statusHandlingCode { get; set; }

        [Display(Name = "Cost Center")]
        public string? costCenter { get; set; }

        public int? createdByEmpNo { get; set; }
        public string? createdByEmpName { get; set; }
        
        [Display(Name = "Created Date"), DataType(DataType.Date)]
        public DateTime? createDate { get; set; }

        public int? assignedToEmpNo { get; set; }
        public string? assignedToEmpName { get; set; }
        public bool useNewWF { get; set; }
        public string? ceaStatusCode { get; set; }
        public string? ceaStatusDesc { get; set; }
        #endregion

        #region Extended Properties
        [Display(Name = "Created By")]
        public string createdByName 
        { 
            get
            {
                if (this.createdByEmpNo > 0)
                    return $"{this.createdByEmpNo} - {this.createdByEmpName}";
                else
                    return this.createdByEmpName!;
            }
        }

        [Display(Name = "Currently Assigned To")]
        public string currentlyAssignedTo
        {
            get
            {
                if (this.assignedToEmpNo > 0)
                    return $"{this.assignedToEmpNo} - {this.assignedToEmpName}";
                else
                    return string.Empty;
            }
        }

        public string useNewWFString
        {
            get
            {
                if (this.useNewWF)
                    return "1";
                else
                    return string.Empty;
            }
        }

        public string? WorkflowID { get; set; }
        #endregion
    }
}
