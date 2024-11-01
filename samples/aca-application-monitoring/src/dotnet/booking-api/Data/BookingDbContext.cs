using Microsoft.EntityFrameworkCore;

namespace BookingApi.Data;

public class BookingDbContext(DbContextOptions<BookingDbContext> options) : DbContext(options) 
{
    public DbSet<BookingMonth> BookingMonths { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<BookingMonth>(builder =>
        {
            builder.HasKey(c => c.DbId);
            builder.Property(c => c.DbId).ValueGeneratedOnAdd().IsRequired();
            builder.Property(c => c.CreditId).IsRequired();
            builder.Property(c => c.Month).IsRequired();
            builder.HasMany(c => c.Bookings).WithOne().HasForeignKey("BookingMonthDbId").OnDelete(DeleteBehavior.Cascade).IsRequired();
            
            builder.Ignore(c => c.Total);
        });
        
        modelBuilder.Entity<Booking>(builder =>
        {
            builder.HasKey(b => b.DbId);
            builder.Property(b => b.DbId).ValueGeneratedOnAdd().IsRequired();
            builder.Property(b => b.Value).IsRequired();
        });
    }
}