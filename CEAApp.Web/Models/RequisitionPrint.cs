namespace CEAApp.Web.Models
{
    public partial class RequisitionPrint
    {

        public decimal RequisitionID { get; set; }
        public string? ProjectNo { get; set; }
        public string? CostCenerID { get; set; }
        public string? CostCener { get; set; }
        public string? ExpenditureType { get; set; }
        public string? RequisitionNo { get; set; }
        public string? RequestDate { get; set; }
        public string? Description { get; set; }
        public string? Reason { get; set; }
        public string? RequisitionDescription { get; set; }
        public string? DateofComission { get; set; }
        public string? PlantLocationID { get; set; }
        public Int16 EstimatedLifeSpan { get; set; }
        public string? ProjectBalanceAmt { get; set; }
        public string? AdditionalBudgetAmt { get; set; }
        public string? RequestedAmt { get; set; }
        public string? UsedAmt { get; set; }
        public string? ProjectAmount { get; set; }
        public string? CategoryCode1 { get; set; }
        public string? CategoryCode2 { get; set; }
        public string? CategoryCode3 { get; set; }
        public string? CategoryCode4 { get; set; }
        public string? CategoryCode5 { get; set; }
        public string? CreateBy { get; set; }
        public string? CreateDate { get; set; }
        public string? LastUpdateBy { get; set; }
        public DateTime? LastUpdateDate { get; set; }
        public string? AccountNo { get; set; }
        public string? ReasonForAdditionalAmt { get; set; }
        public string? RequisitionStatus { get; set; }
        public string? BudgetNotAvailable { get; set; }
        public string? AdditionalAmtRequested { get; set; }
        public string? EquipmentNo { get; set; }
        public string? EquipmentParentNo { get; set; }
        public string? Originator { get; set; }
        public string? ApproverName { get; set; }
        public string? StatusDate { get; set; }

        public Int16? FiscalYear { get; set; }
        public Int16? Id { get; set; }
        public Int16? BudgetYear { get; set; }
        public string? StartDate { get; set; }
        public string? Title { get; set; }
        public string? AccountDescription { get; set; }

    }
}
