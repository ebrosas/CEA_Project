using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace CEAApp.Web.Models
{
    public class CEARequest
    {
        #region Properties        
        public decimal RequisitionID { get; set; }

        [Display(Name = "Requisition No.")]
        public string RequisitionNo { get; set; } = null!;

        [Key]
        [Display(Name = "Project No.")]
        public string ProjectNo { get; set; } = null!;

        [Display(Name = "Cost Center")]
        public string CostCenter { get; set; } = null!;
        public string CostCenterName { get; set; } = null!;

        [Display(Name = "Expenditure Type")]
        public string ExpenditureTypeCode { get; set; } = null!;

        [Display(Name = "Expenditure Type")]
        public string ExpenditureType { get; set; } = null!;

        [Display(Name = "Date"), DataType(DataType.Date)]
        public DateTime? RequestDate { get; set; }

        [Display(Name = "Item Required")]
        public string Description { get; set; } = null!;

        [Display(Name = "Date of Comission"), DataType(DataType.Date)]
        public DateTime DateofComission { get; set; }

        [Display(Name = "Plant Location")]
        public string? PlantLocationID { get; set; }

        [Display(Name = "Est. Life Span")]
        public short EstimatedLifeSpan { get; set; }

        [Display(Name = "Balance Project Amount")]
        [DisplayFormat(DataFormatString = "{0:0.000}", ApplyFormatInEditMode = true)]
        public decimal ProjectBalanceAmt { get; set; }

        [Display(Name = "Additional Amount")]
        [DisplayFormat(DataFormatString = "{0:0.000}", ApplyFormatInEditMode = true)]
        public decimal AdditionalBudgetAmt { get; set; }
        public decimal AdditionalBudgetAmtSync { get; set; }

        [Display(Name = "Estimated Cost"), DataType(DataType.Currency), Column(TypeName = "decimal(18,3)")]
        public decimal RequestedAmt { get; set; }

        [Display(Name = "Item Type")]
        public string CategoryCode1 { get; set; } = null!;
        public string CategoryCode2 { get; set; } = null!;
        public string CategoryCode3 { get; set; } = null!;
        public string CategoryCode4 { get; set; } = null!;
        public string CategoryCode5 { get; set; } = null!;

        public int CreatedByEmpNo { get; set; }
        [Display(Name = "Prepared By")]
        public string CreatedByEmpName { get; set; } = null!;

        [Display(Name = "Created Date")]
        public DateTime CreateDate { get; set; }

        public string LastUpdateBy { get; set; } = null!;

        public DateTime LastUpdateDate { get; set; }

        [Display(Name = "Reason for Requisition")]
        public string Reason { get; set; } = null!;

        [Display(Name = "Account No.")]
        public string AccountNo { get; set; } = null!;

        [Display(Name = "Used Amount")]
        [DisplayFormat(DataFormatString = "{0:0.000}", ApplyFormatInEditMode = true)]
        public decimal? UsedAmount { get; set; }

        [Display(Name = "Budgeted Project Amount")]
        [DisplayFormat(DataFormatString = "{0:0.000}", ApplyFormatInEditMode = true)]
        public decimal? ProjectAmount { get; set; }

        public string CurrentApproval { get; set; } = null!;

        [Display(Name = "Requisition Status")]
        public string RequisitionStatus { get; set; } = null!;

        [Display(Name = "Requisition Description")]
        public string RequisitionDescription { get; set; } = null!;

        [Display(Name = "Reason for Additional Amount")]
        public string ReasonForAdditionalAmt { get; set; } = null!;

        [Display(Name = "Fiscal Year")]
        public int FiscalYear { get; set; }

        [Display(Name = "Equipment No.")]
        public string? EquipmentNo { get; set; }

        [Display(Name = "Equipment Description")]
        public string? EquipmentDesc { get; set; }

        [Display(Name = "Equipment Parent No.")]
        public string? EquipmentParentNo { get; set; }

        [Display(Name = "Equipment Parent Desc.")]
        public string? EquipmentParentDesc { get; set; }

        public int OriginatorEmpNo { get; set; }

        [Display(Name = "Originator")]
        public string OriginatorEmpName { get; set; } = null!;
        public string BudgetStatus { get; set; } = null!;
        public string ExpenseJSON { get; set; } = null!;
        public string AttachmentJSON { get; set; } = null!;
        public bool MultipleItems { get; set; }
        public int? AssignedEmpNo { get; set; }
        public string? AssignedEmpName { get; set; }
        public string? ApprovalStatus { get; set; }
        public string? CEAStatusCode { get; set; }

        [Display(Name = "Requisition Status")]
        public string? CEAStatusDesc { get; set; }
        #endregion

        #region Schedule of Expenses Properties
        public List<FinancialDetail>? ScheduleExpenseList { get; set; } = null!;        
        public bool IsDummy { get; set; }

        [Display(Name = "Year")]
        public string? ExpenseYear { get; set; }

        [Display(Name = "Quarter")]
        public string? ExpenseQuarter { get; set; } 

        [Display(Name = "Amount"), DataType(DataType.Currency), Column(TypeName = "decimal(18,3)")]
        public decimal? ExpenseAmount { get; set; }        
        #endregion

        #region Attachment Properties
        public List<FileAttachment>? AttachmentList { get; set; } = null!;
        #endregion

        #region Additional Properties
        public bool IsDraft { get; set; }
        public int ButtonActionType { get; set; }
        public string? StatusHandlingCode { get; set; }
        public string? CreatedByUserID { get; set; }
        public string? WorkstationID { get; set; }

        [Display(Name = "Approver Comments")]
        public string? ApproverComments { get; set; }
        #endregion

        #region Worfklow Properties
        public bool UseNewWF { get; set; }
        public string? WorkflowID { get; set; }
        public int? WFActionType { get; set; }
        public int? WFRoutineSequence { get; set; }

        [Display(Name = "Approval Role")]
        public string? CurrentWFActivity { get; set; }

        [Display(Name = "Currently Assigned To")]
        public string CurrentlyAssignedTo 
        { 
            get
            {
                if (this.AssignedEmpNo > 0)
                    return $"{this.AssignedEmpNo} - {this.AssignedEmpName}";
                else
                    return "<Not Assigned>";
            }
        }
        #endregion
    }
}
