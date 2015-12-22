CREATE TABLE [dbo].[tdc_bin_master]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[warehouse_no] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[usage_type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[size_group_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost_group_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_code_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seq_no] [int] NULL,
[sort_method] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[relative_point_x] [int] NULL,
[relative_point_y] [int] NULL,
[relative_point_z] [int] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_modified_date] [datetime] NOT NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bm_udef_a] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bm_udef_b] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bm_udef_c] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bm_udef_d] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bm_udef_e] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[maximum_level] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[tdc_bin_master_tg] ON [dbo].[tdc_bin_master]
FOR  UPDATE 
AS
	

DECLARE 	@strBin_No VARCHAR(12) ,
		@strLocation VARCHAR(10) ,
		@strStatus varchar(2),
		@strErrorMsg VARCHAR(200)
/* DMcMinoway  Do Not allow a user to set a bin to INACTIVE Status IF:
	1.) it exists in lot_bin_stock
	2.) it exists in ad_hoc_receipts
	3.) it exists in either the bin_no, or next_op field of tdc_pick_queue
	4.) it exists in either the bin_no, or next_op field of tdc_put_queue
*/

SELECT @strErrorMsg = '' --Initialize the Error Message 

SELECT @strStatus = status , @strBin_No = bin_no , @strLocation = location FROM INSERTED 

IF  @strStatus = 'I' --Being set to INACTIVE so perform checks
	BEGIN

		IF (SELECT COUNT(*)  FROM lot_bin_stock  
			WHERE bin_no =  @strBin_No
			AND location     =  @strLocation ) > 0
			BEGIN
				SELECT @strErrorMsg =  'This bin has inventory and cannot be set to Inactive.'

			END
		IF @strErrorMsg = '' AND 
			(SELECT COUNT(*) FROM tdc_adhoc_receipts 
				WHERE bin_no = @strBin_No
				AND location     =  @strLocation) > 0
			BEGIN
				SELECT @strErrorMsg =  'This bin has inventory and cannot be set to Inactive.'

			END
		
		IF @strErrorMsg = '' AND
		  (SELECT COUNT(*) FROM tdc_pick_queue 
			WHERE (bin_no = @strBin_No OR next_op = @strBin_No)
			AND location     =  @strLocation) > 0
			BEGIN
				SELECT @strErrorMsg =  'This bin has inventory and cannot be set to Inactive.'
			END

		IF @strErrorMsg = '' AND
		  (SELECT COUNT(*) FROM tdc_put_queue 
			WHERE (bin_no = @strBin_No OR next_op = @strBin_No)
			AND location     =  @strLocation) > 0
			BEGIN
				SELECT @strErrorMsg =  'This bin has inventory and cannot be set to Inactive.'
			END


	END


-- Okay now if there is an error msg lets show it
IF @strErrorMsg <> ''
	BEGIN

		ROLLBACK TRAN
		RAISERROR (@strErrorMsg, 16 , 1)
		
	END 

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[tdc_bin_master_trg]
ON [dbo].[tdc_bin_master] FOR INSERT, UPDATE
AS
BEGIN

	DELETE	a
	FROM	cvo_non_allocating_bins a
	JOIN	inserted b
	ON		a.location = b.location
	AND		a.bin_no = b.bin_no
	WHERE	ISNULL(b.bm_udef_e,'') <> '1'

	INSERT	cvo_non_allocating_bins (location, bin_no)
	SELECT	a.location, a.bin_no
	FROM	inserted a
	LEFT JOIN cvo_non_allocating_bins b
	ON		a.location = b.location
	AND		a.bin_no = b.bin_no	
	WHERE	ISNULL(a.bm_udef_e,'') = '1'
	AND		b.location IS NULL
	AND		b.bin_no IS NULL

END

GO
ALTER TABLE [dbo].[tdc_bin_master] ADD CONSTRAINT [PK_tdc_bin_master_1__17] PRIMARY KEY CLUSTERED  ([bin_no], [location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_location_idx3] ON [dbo].[tdc_bin_master] ([group_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_location_idx1] ON [dbo].[tdc_bin_master] ([location], [bin_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_bin_udef_e_idx1] ON [dbo].[tdc_bin_master] ([location], [bin_no], [bm_udef_e]) WITH (ALLOW_PAGE_LOCKS=OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_bin_master_idx4_100413] ON [dbo].[tdc_bin_master] ([location], [group_code], [usage_type_code]) INCLUDE ([bin_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_bin_usage_idx1] ON [dbo].[tdc_bin_master] ([location], [usage_type_code], [bin_no]) INCLUDE ([group_code]) WITH (ALLOW_PAGE_LOCKS=OFF) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_bin_master] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_bin_master] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_bin_master] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_bin_master] TO [public]
GO
