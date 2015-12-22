CREATE TABLE [dbo].[options]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[feature] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[option_part] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[default_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[default_qty] [decimal] (20, 8) NULL CONSTRAINT [DF__options__default__6C44F465] DEFAULT ((0)),
[max_qty] [decimal] (20, 8) NULL CONSTRAINT [DF__options__max_qty__6D39189E] DEFAULT ((0))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600delopt] ON [dbo].[options]
 FOR DELETE
AS
begin
   delete options_clude
     from deleted
    where deleted.part_no = options_clude.part_no and
          deleted.feature = options_clude.feature and
          deleted.option_part = options_clude.option_part
end

GO
CREATE UNIQUE CLUSTERED INDEX [opt1] ON [dbo].[options] ([part_no], [feature], [option_part]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[options] TO [public]
GO
GRANT SELECT ON  [dbo].[options] TO [public]
GO
GRANT INSERT ON  [dbo].[options] TO [public]
GO
GRANT DELETE ON  [dbo].[options] TO [public]
GO
GRANT UPDATE ON  [dbo].[options] TO [public]
GO
