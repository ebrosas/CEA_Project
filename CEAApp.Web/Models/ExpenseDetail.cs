using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models
{
    public class ExpenseDetail
    {
        #region Properties
        [Key]
        public string ceaNumber { get; set; } = null!;

        [Display(Name = "Cost Center")]
        public string costCenter { get; set; } = null!;

        [Display(Name = "Cost Center Name")]
        public string costCenterName { get; set; } = null!;

        [Display(Name = "Order #")]
        public double? orderNumber { get; set; }

        [Display(Name = "Order Date")]
        public DateTime? orderDate { get; set; }

        [Display(Name = "Line #")]
        public double? lineNo { get; set; }

        [Display(Name = "Description 1")]
        public string description1 { get; set; } = null!;

        [Display(Name = "Description 2")]
        public string description2 { get; set; } = null!;

        [Display(Name ="Vendor")]
        public string vendor { get; set; } = null!;

        [Display(Name = "Qty.")]
        public decimal? quantity { get; set; }

        [Display(Name = "Currency")]
        public string currencyCode { get; set; } = null!;

        [Display(Name = "Currency Amt.")]
        public decimal? currencyAmount { get; set; }

        [Display(Name = "PO (BD)")]
        public decimal? poAmount { get; set; }

        [Display(Name = "GL (BD)")]
        public decimal? glAmount { get; set; }

        [Display(Name = "Line Total")]
        public decimal? lineTotal { get; set; }

        [Display(Name = "Requisition Amount (BD)")]
        public decimal? requestedAmt { get; set; }

        [Display(Name = "PO Total (BD)")]
        public decimal? poTotal { get; set; }

        [Display(Name = "GL Total (BD)")]
        public decimal? glTotal { get; set; }

        [Display(Name = "Requisition Balance (BD)")]
        public decimal? balance { get; set; }
        public decimal? percentageUsed { get; set; }
        #endregion

        #region Extended Properties
        public string? costCenterFullName
        {
            get
            {
                if (!string.IsNullOrWhiteSpace(this.costCenter))
                    return $"{this.costCenter} - {this.costCenterName}";
                else
                    return string.Empty;
            }
        }
        #endregion
    }
}
