SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_package_group_save_sp]
		@PKG_Group_Code         varchar(10),
		@Description            varchar(80),
		@Modified_By            varchar(50),
		@PG_Udef_A		varchar(30),
		@PG_Udef_B		varchar(30),
		@PG_Udef_C		varchar(30),
		@PG_Udef_D		varchar(30),
		@PG_Udef_E		varchar(30)

AS


IF EXISTS(SELECT * FROM tdc_package_group WHERE pkg_group_code = @PKG_Group_Code)
BEGIN
	UPDATE tdc_package_group  
	   SET [description]      = @Description,
	       pg_udef_a	  = @PG_Udef_A,
	       pg_udef_b	  = @PG_Udef_B,
	       pg_udef_c	  = @PG_Udef_C,
	       pg_udef_d	  = @PG_Udef_D, 
	       pg_udef_e	  = @PG_Udef_E,
	       last_modified_date = GETDATE(),
	       modified_by	  = @Modified_By
         WHERE pkg_group_code     = @PKG_Group_Code
END
ELSE
BEGIN
	INSERT INTO tdc_package_group
		(pkg_group_code, [description], last_modified_date, modified_by, pg_udef_a, pg_udef_b, pg_udef_c, pg_udef_d, pg_udef_e)	  
	VALUES (@PKG_Group_Code, @Description, GETDATE(), @Modified_By, @PG_Udef_A, @PG_Udef_B, @PG_Udef_C, @PG_Udef_D, @PG_Udef_E)
END
GO
GRANT EXECUTE ON  [dbo].[tdc_package_group_save_sp] TO [public]
GO
