using System;
using System.Collections.Generic;

namespace CEAApp.Web.Models;

public partial class ApprovalStatus
{
    public decimal ApprovalStatusId { get; set; }

    public string? ApprovalStatus1 { get; set; }

    public string? Description { get; set; }

    public string? StatusCode { get; set; }
}
