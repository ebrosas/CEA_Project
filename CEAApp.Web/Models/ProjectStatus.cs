using System;
using System.Collections.Generic;

namespace CEAApp.Web.Models;

public partial class ProjectStatus
{
    public decimal ProjectStatusId { get; set; }

    public decimal ProjectId { get; set; }

    public DateTime? StatusDate { get; set; }

    public int? ProjectStatus1 { get; set; }

    public string? Comment { get; set; }

    public string? CreateBy { get; set; }

    public bool NonBudgeted { get; set; }
}
