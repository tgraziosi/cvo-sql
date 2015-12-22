CREATE TABLE [dbo].[glseg2]
(
[timestamp] [timestamp] NOT NULL,
[seg_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[short_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_type] [smallint] NOT NULL,
[new_flag] [smallint] NOT NULL,
[consol_type] [smallint] NOT NULL,
[consol_detail_flag] [smallint] NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create trigger [dbo].[glseg2_delete] on [dbo].[glseg2] for delete
as
begin
  /* Halt processing if no records were affected */
  if (@@ROWCOUNT = 0)
    return

  delete frl_seg_desc
   where entity_num =1
     and seg_num = 2
     and seg_code in (select seg_code from deleted)

end
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create trigger [dbo].[glseg2_insert] on [dbo].[glseg2] for insert
as
begin
  /* Halt processing if no records were affected */
  if (@@ROWCOUNT = 0)
    return

  insert into frl_seg_desc (seg_code, entity_num, seg_num, 
				seg_code_desc, seg_short_desc)
    select seg_code, 1, 2, description, substring(short_desc, 1, 15)
      from inserted
end
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create trigger [dbo].[glseg2_update] on [dbo].[glseg2] for update
as
begin
  /* Halt processing if no records were affected */
  if (@@ROWCOUNT = 0)
    return

  delete frl_seg_desc
   where entity_num =1
     and seg_num = 2
     and seg_code in (select seg_code from deleted)

  insert into frl_seg_desc (seg_code, entity_num, seg_num, 
				seg_code_desc, seg_short_desc)
    select seg_code, 1, 2, description, substring(short_desc, 1, 15)
      from inserted
end
GO
CREATE UNIQUE CLUSTERED INDEX [glseg2_ind_0] ON [dbo].[glseg2] ([seg_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glseg2] TO [public]
GO
GRANT SELECT ON  [dbo].[glseg2] TO [public]
GO
GRANT INSERT ON  [dbo].[glseg2] TO [public]
GO
GRANT DELETE ON  [dbo].[glseg2] TO [public]
GO
GRANT UPDATE ON  [dbo].[glseg2] TO [public]
GO
