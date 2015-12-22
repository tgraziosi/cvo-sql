CREATE TABLE [dbo].[resource_group]
(
[timestamp] [timestamp] NOT NULL,
[group_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[resource_part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[use_order] [int] NOT NULL,
[run_factor] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[resource_group_iud]
ON [dbo].[resource_group]

FOR INSERT, UPDATE, DELETE
AS
BEGIN
DECLARE	@rowcount INT,
	@subcount INT,
	@tstcount INT


SELECT @rowcount=@@rowcount


IF UPDATE(group_part_no)
	BEGIN
	SELECT	@tstcount = COUNT(*)	
	FROM	dbo.inv_master IM,
		inserted I
	WHERE	IM.part_no = I.group_part_no
	AND	IM.status = 'R'

	IF @tstcount <> @rowcount
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89711 ,'Illegal column value. GROUP_PART_NO not a resource in INV_MASTER'
		RETURN
		END
	END
IF UPDATE(resource_part_no)
	BEGIN
	SELECT	@tstcount = COUNT(*)	
	FROM	dbo.inv_master IM,
		inserted I
	WHERE	IM.part_no = I.resource_part_no
	AND	IM.status = 'R'

	IF @tstcount <> @rowcount
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89712 ,'Illegal column value. RESOURCE_PART_NO not a resource in INV_MASTER'
		RETURN
		END
	END


IF UPDATE(group_part_no)
	BEGIN
	
	IF EXISTS(SELECT * FROM inserted I, dbo.resource_group RG WHERE RG.resource_part_no = I.group_part_no)
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89713, 'Multi-tier resource groups are not supported'
		RETURN
		END
	END
IF UPDATE(resource_part_no)
	BEGIN
	
	IF EXISTS(SELECT * FROM inserted I, dbo.resource_group RG WHERE RG.group_part_no = I.resource_part_no)
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89713, 'Multi-tier resource groups are not supported'
		RETURN
		END
	END


DECLARE	@check_part_no VARCHAR(30),
	@group_part_no VARCHAR(30),
	@location VARCHAR(10),
	@use_order INT,
	@resource_part_no VARCHAR(30),
	@std_acct_code VARCHAR(8),
	@std_direct_dolrs DECIMAL(20,8),
	@std_ovhd_dolrs DECIMAL(20,8),
	@std_util_dolrs DECIMAL(20,8)


SELECT	@check_part_no=MIN(I.group_part_no)
FROM	inserted I
SELECT	@group_part_no=MIN(D.group_part_no)
FROM	deleted D
IF @check_part_no < @group_part_no OR @group_part_no IS NULL
	SELECT @group_part_no=@check_part_no

WHILE @group_part_no IS NOT NULL
	BEGIN
	
	SELECT	@location=MIN(IL.location)
	FROM	dbo.inv_list IL
	WHERE	IL.part_no = @group_part_no

	WHILE @location IS NOT NULL
		BEGIN
		
		SELECT	@use_order=MIN(RG.use_order),
			@resource_part_no=NULL
		FROM	dbo.resource_group RG,
			dbo.inv_list IL
		WHERE	RG.group_part_no = @group_part_no
		AND	IL.part_no = RG.resource_part_no
		AND	IL.location = @location

		
		IF @use_order IS NOT NULL
			
			SELECT	@resource_part_no=MIN(RG.resource_part_no)
			FROM	dbo.resource_group RG
			WHERE	RG.group_part_no = @group_part_no
			AND	RG.use_order = @use_order

		
		IF @resource_part_no IS NOT NULL
			BEGIN
			SELECT	@std_acct_code=IL.acct_code,
				@std_direct_dolrs=IL.std_direct_dolrs,
				@std_ovhd_dolrs=IL.std_ovhd_dolrs,
				@std_util_dolrs=IL.std_util_dolrs
			FROM	dbo.inv_list IL
			WHERE	IL.part_no = @resource_part_no
			AND	IL.location = @location
			END
		ELSE
			BEGIN
			
			SELECT	@std_acct_code=NULL,
				@std_direct_dolrs=0.0,
				@std_ovhd_dolrs=0.0,
				@std_util_dolrs=0.0
			END

		
		UPDATE	dbo.inv_list
		SET	acct_code = @std_acct_code,
			std_direct_dolrs=@std_direct_dolrs,
			std_ovhd_dolrs=@std_ovhd_dolrs,
			std_util_dolrs=@std_util_dolrs,
			max_stock=0.0
		WHERE	part_no = @group_part_no
		AND	location = @location
		AND	(	acct_code = @std_acct_code
			OR	std_direct_dolrs <> @std_direct_dolrs
			OR	std_ovhd_dolrs <> @std_ovhd_dolrs
			OR	std_util_dolrs <> @std_util_dolrs )

		
		SELECT	@location=MIN(IL.location)
		FROM	dbo.inv_list IL
		WHERE	IL.part_no = @group_part_no
		AND	IL.location > @location
		END

	
	SELECT	@check_part_no=MIN(I.group_part_no)
	FROM	inserted I
	WHERE	I.group_part_no > @group_part_no
	SELECT	@group_part_no=MIN(D.group_part_no)
	FROM	deleted D
	WHERE	D.group_part_no > @group_part_no
	IF @check_part_no < @group_part_no OR @group_part_no IS NULL
		SELECT @group_part_no=@check_part_no
	END

RETURN
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700uidresg] ON [dbo].[resource_group] 
FOR INSERT,UPDATE, DELETE
AS
BEGIN
DECLARE @location VARCHAR(10), @use_order INT, @acct_code VARCHAR(8),
  @std_direct_dolrs DECIMAL(20,8), @std_ovhd_dolrs DECIMAL(20,8), @std_util_dolrs DECIMAL(20,8),

  @i_group_part_no varchar(30), @i_resource_part_no varchar(30), @i_use_order int, @i_run_factor decimal(20,8),
  @d_group_part_no varchar(30), @d_resource_part_no varchar(30), @d_use_order int, @d_run_factor decimal(20,8),

  @l_group_part_no varchar(30), @c_group_part_no varchar(30),
  @il_acct_code VARCHAR(8),
  @il_std_direct_dolrs DECIMAL(20,8), @il_std_ovhd_dolrs DECIMAL(20,8), @il_std_util_dolrs DECIMAL(20,8)

DECLARE resguid CURSOR LOCAL STATIC FOR							-- mls 1/18/07
  select i.group_part_no, i.resource_part_no, i.use_order, i.run_factor,
  d.group_part_no, d.resource_part_no, d.use_order, d.run_factor
  FROM inserted i
  full outer join deleted d on d.group_part_no = i.group_part_no and d.resource_part_no = i.resource_part_no
  order by i.group_part_no, d.group_part_no

DECLARE resgloc CURSOR LOCAL STATIC FOR
  select il.location, il.acct_code, il.std_direct_dolrs, il.std_ovhd_dolrs, il.std_util_dolrs
  from inv_list il
  where il.part_no = @c_group_part_no
  order by il.location

OPEN resguid
FETCH NEXT FROM resguid INTO
  @i_group_part_no , @i_resource_part_no , @i_use_order , @i_run_factor ,
  @d_group_part_no , @d_resource_part_no , @d_use_order , @d_run_factor 

While @@Fetch_status = 0
begin
  -- Make sure all group resource part_no are valid
  IF @i_group_part_no is not NULL and isnull(@i_group_part_no,'') != isnull(@d_group_part_no,'')
  begin
    IF NOT EXISTS (select 1 FROM inv_master IM WHERE IM.part_no = @i_group_part_no and IM.status = 'R' )
    BEGIN
      ROLLBACK TRANSACTION
      exec adm_raiserror 89711 ,'Illegal column value. GROUP_PART_NO not a resource in INV_MASTER'
      RETURN
    END
	
    IF EXISTS(SELECT 1 FROM resource_group RG WHERE RG.resource_part_no = @i_group_part_no)
    BEGIN
      ROLLBACK TRANSACTION
      exec adm_raiserror 89713, 'Multi-tier resource groups are not supported'
      RETURN
    END
  end

  -- Make sure all member resource part_no are valid
  IF @i_resource_part_no is not NULL and isnull(@i_resource_part_no,'') != isnull(@d_resource_part_no,'')
  begin
    IF NOT EXISTS (select 1 FROM inv_master IM WHERE IM.part_no = @i_resource_part_no and IM.status = 'R')
    BEGIN
      ROLLBACK TRANSACTION
      exec adm_raiserror 89712, 'Illegal column value. RESOURCE_PART_NO not a resource in INV_MASTER'
      RETURN
    END

    IF EXISTS(SELECT 1 FROM resource_group RG WHERE RG.group_part_no = @i_resource_part_no)
    BEGIN
      ROLLBACK TRANSACTION
      exec adm_raiserror 89713 ,'Multi-tier resource groups are not supported'
      RETURN
    END
  end

  -- For each group resource modified...
  if @i_group_part_no is not NULL
    select @c_group_part_no = @i_group_part_no
  else
    select @c_group_part_no = @d_group_part_no

  -- For each location of the group...
  if isnull(@l_group_part_no,'') != @c_group_part_no
  begin
    OPEN resgloc
    FETCH NEXT FROM resgloc INTO @location,
      @il_acct_code, @il_std_direct_dolrs, @il_std_ovhd_dolrs, @il_std_util_dolrs

    WHILE @@FETCH_STATUS = 0
    BEGIN
      -- What member has precedence
      SELECT  @use_order=isnull((select MIN(RG.use_order)
      FROM   resource_group RG,   inv_list IL
      WHERE RG.group_part_no = @c_group_part_no AND IL.part_no = RG.resource_part_no
        AND IL.location = @location),NULL)

      -- If there is a member...
      IF @use_order IS NOT NULL
      BEGIN
        -- Get the cost
        SELECT  @acct_code=IL.acct_code,
          @std_direct_dolrs=IL.std_direct_dolrs,
          @std_ovhd_dolrs=IL.std_ovhd_dolrs,
          @std_util_dolrs=IL.std_util_dolrs
        FROM    resource_group RG,   inv_list IL
        WHERE  RG.group_part_no = @c_group_part_no AND  RG.use_order = @use_order
        AND  IL.part_no = RG.resource_part_no AND  IL.location = @location
      END
      ELSE
      BEGIN
        SELECT @acct_code = @il_acct_code,
          @std_direct_dolrs=0.0, @std_ovhd_dolrs=0.0, @std_util_dolrs=0.0
      END

      -- Update the costs if they don't match
      if (  @il_acct_code != @acct_code OR  @il_std_direct_dolrs != @std_direct_dolrs
        OR  @il_std_ovhd_dolrs != @std_ovhd_dolrs OR  @il_std_util_dolrs != @std_util_dolrs)
      begin
        UPDATE    inv_list
        SET  acct_code=@acct_code,
          std_direct_dolrs = @std_direct_dolrs,
          std_ovhd_dolrs = @std_ovhd_dolrs,
          std_util_dolrs = @std_util_dolrs,
          max_stock=0.0
        WHERE  location = @location AND  part_no = @c_group_part_no
      END

      -- Next location
      FETCH NEXT FROM resgloc INTO @location,
        @il_acct_code, @il_std_direct_dolrs, @il_std_ovhd_dolrs, @il_std_util_dolrs
    END
    CLOSE resgloc
   
    select @l_group_part_no = @c_group_part_no
  end -- l_group_part_no != c_group_part_no

  FETCH NEXT FROM resguid INTO
    @i_group_part_no , @i_resource_part_no , @i_use_order , @i_run_factor ,
    @d_group_part_no , @d_resource_part_no , @d_use_order , @d_run_factor 
end

deallocate resgloc 
close resguid
deallocate resguid
END
GO
CREATE UNIQUE CLUSTERED INDEX [resource_group] ON [dbo].[resource_group] ([group_part_no], [resource_part_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[resource_group] TO [public]
GO
GRANT SELECT ON  [dbo].[resource_group] TO [public]
GO
GRANT INSERT ON  [dbo].[resource_group] TO [public]
GO
GRANT DELETE ON  [dbo].[resource_group] TO [public]
GO
GRANT UPDATE ON  [dbo].[resource_group] TO [public]
GO
