CREATE TABLE [dbo].[cc_status_codes]
(
[status_code] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_desc] [varchar] (65) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



create trigger [dbo].[cc_status_code_delete_tr] 
	on [dbo].[cc_status_codes] 
	for delete
AS
	IF (select count(*) from cc_inv_status_hist h, deleted d
		where d.status_code = h.status_code) > 0
	BEGIN
		RAISERROR (50001,16,11)
		ROLLBACK TRAN
	END
GO
CREATE UNIQUE CLUSTERED INDEX [cc_status_codes_idx] ON [dbo].[cc_status_codes] ([status_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_status_codes] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_status_codes] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_status_codes] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_status_codes] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_status_codes] TO [public]
GO
