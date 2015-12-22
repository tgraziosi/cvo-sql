CREATE TABLE [dbo].[mbbmPPFSelectedChildSheets]
(
[TimeStamp] [timestamp] NOT NULL,
[RetrievalID] [uniqueidentifier] NOT NULL,
[ChildSheetID] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[mbbmPPFSelectedChildSheets] ADD CONSTRAINT [PK_mbbmPPFSelectedChildSheets] PRIMARY KEY NONCLUSTERED  ([RetrievalID], [ChildSheetID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IDX_mbbmPPFSelectedChildSheets] ON [dbo].[mbbmPPFSelectedChildSheets] ([RetrievalID]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mbbmPPFSelectedChildSheets] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPPFSelectedChildSheets] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmPPFSelectedChildSheets] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmPPFSelectedChildSheets] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmPPFSelectedChildSheets] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmPPFSelectedChildSheets] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmPPFSelectedChildSheets] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmPPFSelectedChildSheets] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmPPFSelectedChildSheets] TO [public]
GO
