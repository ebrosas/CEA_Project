using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace CEAApp.Web.Models;

public partial class ApplicationDbContext : DbContext
{
    public ApplicationDbContext()
    {
    }

    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<ApprovalStatus> ApprovalStatuses { get; set; }

    public virtual DbSet<Project> Projects { get; set; }

    public virtual DbSet<ProjectStatus> ProjectStatuses { get; set; }

    public virtual DbSet<Requisition> Requisitions { get; set; }

    public DbSet<CostCenters> CostCenter { get; set; }

    public DbSet<ExpenseType> ExpenseType { get; set; }

    public DbSet<FiscalYears> FiscalYears { get; set; }

    public DbSet<DetailedExpensesReport> DetailedExpensesReport { get; set; }

    public DbSet<RequisitionReport> RequisitionReport { get; set; }

    public DbSet<RequisitionPrint> RequisitionPrint { get; set; }

    public virtual DbSet<RequisitionApprover> RequisitionApprover { get; set; }
    
    public virtual DbSet<RequisitionExpense> RequisitionExpense { get; set; }

    public virtual DbSet<ProjectInfo> ProjectDetail { get; set; }
    public virtual DbSet<RequisitionStatus> RequestStatusDetail { get; set; }
    public virtual DbSet<ExpenseDetail> ExpenseList { get; set; }
    public virtual DbSet<EmployeeDetail> EmployeeList { get; set; }
    public virtual DbSet<CEARequest> RequisitionDetail { get; set; }
    public virtual DbSet<WFApprovalStatus> WorkflowStatusDetail { get; set; }
    public virtual DbSet<RequisitionDetail> RequisitionDetailList { get; set; }
    public virtual DbSet<ApproversDetails> ApproversDetailList { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see http://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseSqlServer("Server=GRBHSQDT02;Database=ProjectRequisition;User ID=ceauser;Password=ceapwd;TrustServerCertificate=True;");

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.UseCollation("SQL_Latin1_General_CP1_CI_AS");

        modelBuilder.Entity<ApprovalStatus>(entity =>
        {
            entity.ToTable("ApprovalStatus");

            entity.Property(e => e.ApprovalStatusId)
                .ValueGeneratedOnAdd()
                .HasColumnType("numeric(18, 0)")
                .HasColumnName("ApprovalStatusID");
            entity.Property(e => e.ApprovalStatus1)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("ApprovalStatus");
            entity.Property(e => e.Description)
                .HasMaxLength(100)
                .IsUnicode(false);
            entity.Property(e => e.StatusCode)
                .HasMaxLength(50)
                .IsUnicode(false);
        });

        modelBuilder.Entity<Project>(entity =>
        {
            entity.ToTable("Project");

            entity.HasIndex(e => e.ProjectNo, "Projectno_uk").IsUnique();

            entity.Property(e => e.ProjectId)
                .ValueGeneratedOnAdd()
                .HasColumnType("numeric(18, 0)")
                .HasColumnName("ProjectID");
            entity.Property(e => e.AccountCode)
                .HasMaxLength(12)
                .IsUnicode(false);
            entity.Property(e => e.AccountId)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("AccountID");
            entity.Property(e => e.CategoryCode1)
                .HasMaxLength(10)
                .IsUnicode(false);
            entity.Property(e => e.CategoryCode2)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.CategoryCode3)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.CategoryCode4)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.CategoryCode5)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.CostCenter)
                .HasMaxLength(12)
                .IsUnicode(false);
            entity.Property(e => e.CreateBy)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.CreateDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Description)
                .HasMaxLength(200)
                .IsUnicode(false);
            entity.Property(e => e.DetailDescription).HasColumnType("text");
            entity.Property(e => e.ExpectedProjectDate).HasColumnType("datetime");
            entity.Property(e => e.ExpenditureType)
                .HasMaxLength(10)
                .IsUnicode(false);
            entity.Property(e => e.LastUpdateBy)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.LastUpdateDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.ObjectCode)
                .HasMaxLength(12)
                .IsUnicode(false);
            entity.Property(e => e.ProjectAmount).HasColumnType("numeric(18, 3)");
            entity.Property(e => e.ProjectNo)
                .HasMaxLength(12)
                .IsUnicode(false);
            entity.Property(e => e.ProjectType)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasDefaultValueSql("('NonBudgeted')");
            entity.Property(e => e.SubjectCode)
                .HasMaxLength(12)
                .IsUnicode(false);
        });

        modelBuilder.Entity<ProjectStatus>(entity =>
        {
            entity.HasKey(e => new { e.ProjectStatusId, e.ProjectId });

            entity.ToTable("ProjectStatus");

            entity.HasIndex(e => e.ProjectId, "Indx_ProSta_P").HasFillFactor(80);

            entity.Property(e => e.ProjectStatusId)
                .ValueGeneratedOnAdd()
                .HasColumnType("numeric(18, 0)")
                .HasColumnName("ProjectStatusID");
            entity.Property(e => e.ProjectId)
                .HasColumnType("numeric(18, 0)")
                .HasColumnName("ProjectID");
            entity.Property(e => e.Comment)
                .HasMaxLength(100)
                .IsUnicode(false);
            entity.Property(e => e.CreateBy)
                .HasMaxLength(50)
                .IsUnicode(false);
            entity.Property(e => e.ProjectStatus1).HasColumnName("ProjectStatus");
            entity.Property(e => e.StatusDate).HasColumnType("datetime");
        });

        modelBuilder.Entity<Requisition>(entity =>
        {
            entity.ToTable("Requisition");

            entity.Property(e => e.RequisitionId)
                .ValueGeneratedOnAdd()
                .HasColumnType("numeric(18, 0)")
                .HasColumnName("RequisitionID");
            entity.Property(e => e.AdditionalBudgetAmt).HasColumnType("numeric(18, 3)");
            entity.Property(e => e.CategoryCode1)
                .HasMaxLength(10)
                .IsUnicode(false)
                .HasDefaultValueSql("('')");
            entity.Property(e => e.CategoryCode2)
                .HasMaxLength(1)
                .IsUnicode(false)
                .HasDefaultValueSql("('0')")
                .HasComment("This column is to check whether the CEA/MRE/INC is for a single or multiple items. 0 - single, 1- multiple");
            entity.Property(e => e.CategoryCode3)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasDefaultValueSql("('')");
            entity.Property(e => e.CategoryCode4)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasDefaultValueSql("('')");
            entity.Property(e => e.CategoryCode5)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasDefaultValueSql("('')");
            entity.Property(e => e.CreateBy)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasDefaultValueSql("('')");
            entity.Property(e => e.CreateDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.DateofComission)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.Description)
                .HasMaxLength(1000)
                .IsUnicode(false)
                .HasDefaultValueSql("('')");
            entity.Property(e => e.EquipmentNo)
                .HasMaxLength(12)
                .IsUnicode(false)
                .HasDefaultValueSql("('')");
            entity.Property(e => e.EquipmentParentNo)
                .HasMaxLength(12)
                .IsUnicode(false)
                .HasDefaultValueSql("('')");
            entity.Property(e => e.LastUpdateBy)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasDefaultValueSql("('')");
            entity.Property(e => e.LastUpdateDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.OneWorldAbno).HasColumnName("OneWorldABNo");
            entity.Property(e => e.PlantLocationId)
                .HasMaxLength(12)
                .IsUnicode(false)
                .HasDefaultValueSql("((0))")
                .HasColumnName("PlantLocationID");
            entity.Property(e => e.ProjectBalanceAmt).HasColumnType("numeric(18, 3)");
            entity.Property(e => e.ProjectNo)
                .HasMaxLength(12)
                .IsUnicode(false);
            entity.Property(e => e.Reason)
                .HasMaxLength(1000)
                .IsUnicode(false)
                .HasDefaultValueSql("('')");
            entity.Property(e => e.ReasonForAdditionalAmt)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasDefaultValueSql("('')");
            entity.Property(e => e.RequestDate)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.RequestedAmt).HasColumnType("numeric(18, 3)");
            entity.Property(e => e.RequisitionDescription)
                .HasMaxLength(40)
                .IsUnicode(false)
                .HasDefaultValueSql("('')");
            entity.Property(e => e.RequisitionNo)
                .HasMaxLength(50)
                .IsUnicode(false);
        });

        modelBuilder.Entity<CostCenters>()
               .HasNoKey()
               .ToView("expenseReportVM");

        modelBuilder.Entity<DetailedExpensesReport>()
            .HasNoKey()
            .ToView("DetailedExpensesReportVM");

        modelBuilder.Entity<RequisitionReport>()
            .HasNoKey()
            .ToView("RequisitionReportVM");

        modelBuilder.Entity<RequisitionPrint>()
           .HasNoKey()
           .ToView("RequisitionPrint");

        modelBuilder.Entity<RequisitionApprover>()
          .HasNoKey();

        modelBuilder.Entity<RequisitionExpense>()
          .HasNoKey();

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
