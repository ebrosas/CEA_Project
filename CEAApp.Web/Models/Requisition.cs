using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace CEAApp.Web.Models;

public partial class Requisition
{
    public decimal RequisitionId { get; set; }

    public string ProjectNo { get; set; } = null!;

    public string RequisitionNo { get; set; } = null!;

    public string Status { get; set; } = null!;

    [Display(Name = "Requisition Date"), DataType(DataType.Date)]
    public DateTime? RequestDate { get; set; }

    public string Description { get; set; } = null!;

    public DateTime? DateofComission { get; set; }

    public string PlantLocationId { get; set; } = null!;

    public short EstimatedLifeSpan { get; set; }

    public decimal ProjectBalanceAmt { get; set; }

    public decimal AdditionalBudgetAmt { get; set; }

    public decimal RequestedAmt { get; set; }

    public string CategoryCode1 { get; set; } = null!;

    /// <summary>
    /// This column is to check whether the CEA/MRE/INC is for a single or multiple items. 0 - single, 1- multiple
    /// </summary>
    public string CategoryCode2 { get; set; } = null!;

    public string CategoryCode3 { get; set; } = null!;

    public string CategoryCode4 { get; set; } = null!;

    public string CategoryCode5 { get; set; } = null!;

    public string CreateBy { get; set; } = null!;

    public DateTime CreateDate { get; set; }

    public string LastUpdateBy { get; set; } = null!;

    public DateTime LastUpdateDate { get; set; }

    public string Reason { get; set; } = null!;

    public string RequisitionDescription { get; set; } = null!;

    public string ReasonForAdditionalAmt { get; set; } = null!;

    public int FiscalYear { get; set; }

    public double OneWorldAbno { get; set; }

    public int OriginatorEmpNo { get; set; }

    public bool EquipmentNoRequired { get; set; } = false;

    public string EquipmentNo { get; set; } = null!;

    public string EquipmentParentNo { get; set; } = null!;

    public int CreatedByEmpNo { get; set; }

    public bool EquipmentNoMandatory { get; set; }

    public string ExpenditureType { get; set; } = null!;

    public string AccountNo { get; set; } = null!;

    public string EquipmentDescription { get; set; } = null!;

    public string EquipmentParentDescription { get; set; } = null!;

    public string? ObjectCode { get; set; }

    public string? SubjectCode { get; set; }

    public string? AccountCode { get; set; }

    public string? CostCenter { get; set; }

    public string? CompanyCode { get; set; }

    public string? StatusCode { get; set; }

    public string? statusHandlingCode { get; set; }

    public string? CEAStatusCode { get; set; }

    public string? CEAStatusDesc { get; set; }


}
