using System.ComponentModel.DataAnnotations;
using System.Reflection.Metadata.Ecma335;

namespace CEAApp.Web.Models
{
    public class ProjectInfo
    {
        #region Properties
        public decimal ProjectID { get; set; }

        [Key]
        [Display(Name ="Project No.")]
        public string? ProjectNo { get; set; }

        [Display(Name = "Budget Year"), Required]
        public int FiscalYear { get; set; }

        [Display(Name = "Expected Project Date"), DataType(DataType.Date), Required]
        public DateTime? ExpectedProjectDate { get; set; }

        [Display(Name = "Company Code")]
        public int CompanyCode { get; set; }
        
        [Display(Name = "Cost Center"), Required]
        public string? CostCenter { get; set; }
        
        [Display(Name = "Cost Center Name")]
        public string? CostCenterName { get; set; }

        [Display(Name = "Expenditure Type"), Required]
        public string? ExpenditureType { get; set; }

        [Display(Name = "Description"), Required, StringLength(200, ErrorMessage = "Maximum input is 200 chars. only!")]
        public string? Description { get; set; }

        [Display(Name = "Detailed Description")]
        public string? DetailDescription { get; set; }

        [Display(Name = "Account No.")]
        public string? AccountNo { get; set; }

        [Display(Name = "Budgeted Project Amount"), DataType(DataType.Currency), Required]
        public decimal ProjectAmount { get; set; }

        [Display(Name = "Used Amount"), DataType(DataType.Currency)]
        public decimal? UsedAmount { get; set; }

        [Display(Name = "Balance Amount"), DataType(DataType.Currency)]
        public decimal? BalanceAmount { get; set; }

        [Display(Name = "Project Status")]
        public string? ProjectStatus { get; set; }

        [Display(Name = "Author")]
        public string? StatusAuthor { get; set; }

        [Display(Name = "Comments")]
        public string? Comment { get; set; }

        [Display(Name = "Budget Status")]
        public string? BudgetStatus { get; set; }

        [Display(Name = "Additional Amount"), DataType(DataType.Currency)]
        public decimal? AdditionalAmount { get; set; }

        [Display(Name ="Expenditure Type")]
        public string? ExpenditureTypeCode { get; set; }

        [Display(Name = "Account Code")]
        public string? AccountCode { get; set; }

        [Display(Name = "Object Code")]
        public string? ObjectCode { get; set; }

        [Display(Name = "Subject Code")]
        public string? SubjectCode { get; set; }
        #endregion

        #region Extended Properties
        //[Display(Name = "Account No.")]
        //public string AccountNo 
        //{ 
        //    get
        //    {
        //        if (!string.IsNullOrWhiteSpace(this.AccountCode) && !string.IsNullOrWhiteSpace(this.ObjectCode) && !string.IsNullOrWhiteSpace(this.SubjectCode))
        //            return $"{this.AccountCode!.Trim()}.{this.ObjectCode!.Trim()}.{this.SubjectCode!.Trim()}";
        //        else
        //            return string.Empty;
        //    }
        //}
        #endregion
    }
}
