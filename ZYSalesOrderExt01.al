tableextension 50114 ZYSalesHeaderExt extends "Sales Header"
{
    fields
    {
        field(50101; "Large Text"; Blob)
        {
            Caption = 'Large Text';
            DataClassification = CustomerContent;
        }
    }
}
pageextension 50114 ZYSalesOrderExt extends "Sales Order"
{
    layout
    {
        addlast(General)
        {
            field(LargeText; LargeText)
            {
                Caption = 'Large Text';
                ApplicationArea = All;
                MultiLine = true;
                ShowCaption = false;
                trigger OnValidate()
                begin
                    SetLargeText(LargeText);
                end;
            }
        }
    }

    actions
    {
        addafter(Post)
        {
            action(SaveReportAsEncodedText)
            {
                Caption = 'Save Sales Report As Encoded Text';
                Image = Transactions;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    Base64Convert: Codeunit "Base64 Convert";
                    InStr: InStream;
                    OutStr: OutStream;
                    SalesHeader: Record "Sales Header";
                    RecRef: RecordRef;
                    FldRef: FieldRef;
                    TempBlob: Codeunit "Temp Blob";
                begin
                    if SalesHeader.Get(Rec."Document Type", Rec."No.") then begin
                        RecRef.GetTable(SalesHeader);
                        FldRef := RecRef.Field(SalesHeader.FieldNo("No."));
                        FldRef.SetRange(SalesHeader."No.");
                        TempBlob.CreateOutStream(OutStr);
                        Report.SaveAs(Report::"Standard Sales - Order Conf.", '', ReportFormat::Pdf, OutStr, RecRef);
                        TempBlob.CreateInStream(InStr);
                        LargeText := Base64Convert.ToBase64(InStr, false);
                        SetLargeText(LargeText);
                    end;
                end;
            }
        }
    }
    var
        LargeText: Text;

    trigger OnAfterGetRecord()
    begin
        LargeText := GetLargeText();
    end;

    procedure SetLargeText(NewLargeText: Text)
    var
        OutStream: OutStream;
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(Rec."Document Type", Rec."No.");
        SalesHeader."Large Text".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(LargeText);
        SalesHeader.Modify();
    end;

    procedure GetLargeText() NewLargeText: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        Rec.CalcFields("Large Text");
        Rec."Large Text".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), Rec.FieldName("Large Text")));
    end;
}
