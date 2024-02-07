using System;
using System.Collections.Generic;

namespace CEAApp.Web.Models;

public partial class Project
{
    public decimal ProjectId { get; set; }

    public string ProjectNo { get; set; } = null!;

    public Int16 FiscalYear { get; set; }

    public DateTime ExpectedProjectDate { get; set; }

    public Int16 CompanyCode { get; set; }

    public string CostCenter { get; set; } = null!;

    public string ExpenditureType { get; set; } = null!;

    public string? Description { get; set; }

    public string? DetailDescription { get; set; }

    public decimal ProjectAmount { get; set; }

    public string? AccountId { get; set; }

    public string CategoryCode1 { get; set; } = null!;

    public string? CategoryCode2 { get; set; }

    public string? CategoryCode3 { get; set; }

    public string? CategoryCode4 { get; set; }

    public string? CategoryCode5 { get; set; }

    public string? CreateBy { get; set; }

    public DateTime? CreateDate { get; set; }

    public string? LastUpdateBy { get; set; }

    public DateTime? LastUpdateDate { get; set; }

    public string? AccountCode { get; set; }

    public string? ObjectCode { get; set; }

    public string? SubjectCode { get; set; }

    public string ProjectType { get; set; } = null!;

    //public string Object { get; set; } = null!;

    //public string? Subject { get; set; }
}
