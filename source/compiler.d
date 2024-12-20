import std;
import colorize;
import data;
import thepath;
class Tokenizer
{
    string source;
    int pos;
    int start;
    int line;
    int col;
    bool err;
    bool imports;
    Token[] tokens;
    string file;
    TokenType[string] keywords;
    TokenType[string] registers;
    this(){
        registers["A"] = TokenType.REG_A;
        registers["B"] = TokenType.REG_B;
        registers["C"] = TokenType.REG_C;
        registers["D"] = TokenType.REG_D;
        registers["E"] = TokenType.REG_E;
        registers["F"] = TokenType.REG_F;
        registers["G"]=TokenType.REG_G;
        registers["H"]=TokenType.REG_H;
        registers["I"]=TokenType.REG_I;
        registers["J"]=TokenType.REG_J;
        keywords["nop"]=TokenType.NOP;
        keywords["add"]=TokenType.ADD;
        keywords["addf"]=TokenType.ADDF;
        keywords["sub"]=TokenType.SUB;
        keywords["subf"]=TokenType.SUBF;
        keywords["mul"]=TokenType.MUL;
        keywords["mulf"]=TokenType.MULF;
        keywords["and"]=TokenType.AND;
        keywords["not"]=TokenType.NOT;
        keywords["or"]=TokenType.OR;
        keywords["xor"]=TokenType.XOR;
        keywords["cp"]=TokenType.CP;
        keywords["jmp"]=TokenType.JMP;
        keywords["jnz"]=TokenType.JNZ;
        keywords["jz"]=TokenType.JZ;
        keywords["cmp"]=TokenType.CMP;
        keywords["sys"]=TokenType.SYS;
        keywords["div"]=TokenType.DIV;
        keywords["mod"]=TokenType.MOD;
        keywords["read"]=TokenType.READ;
        keywords["write"]=TokenType.WRITE;
        keywords["push"]=TokenType.PUSH;
        keywords["pop"]=TokenType.POP;
        keywords["mov"]=TokenType.MOV;
        keywords["call"]=TokenType.CALL;
        keywords["ret"]=TokenType.RET;
        keywords["inc"]=TokenType.INC;
        keywords["dec"]=TokenType.DEC;
        keywords["incf"]=TokenType.INCF;
        keywords["decf"]=TokenType.DECF;
        keywords["bp"]=TokenType.BREAKPOINT;
        keywords["setErrAddr"]=TokenType.SETERRADDR;
        keywords["exit"]=TokenType.EXIT;
        keywords["true"]=TokenType.TRUE;
        keywords["false"]=TokenType.FALSE;
        keywords["null"]=TokenType.NULL;
        keywords["jg"]=TokenType.JG;
        keywords["jlt"]=TokenType.JNG;

    }
    void scanToken(string src)
    {
        char c = advance();
        switch (c)
        {
        case '\n':
            line++;
            col=0;
            return;
        case ' ':return;    
        case '\t':return;
        case '(':
        addToken(TokenType.LPAREN, "(");
        return;
        case ')':
        addToken(TokenType.RPAREN, ")");
        return;
        case '[':
        string contents;
        while((peek()!=']')&&(!isAtEnd())){
            contents~=advance();
        }
        Tokenizer tkbuilder=new Tokenizer();
        tkbuilder.scanTokens(contents,this.file,this.line);
        tkbuilder.tokens.length--;
        Token t;
        t.type=TokenType.ARRAY;
        t.literal=contents;
        t.subtokens=tkbuilder.tokens;
        consume(']',"No closing bracket found");
        addToken(t);
        return;
        case '\'':
        char chars=advance();
        addToken(TokenType.NUMBER,(cast(real)chars).to!string());
        consume('\'',"No closing quote found");
        return;
        case '=':
        addToken(TokenType.EQUALS, "=");
        return;
        case '"':
            string s;
            while (((peek() != '"')&&(peek()!=';')&&(previous()!='\\'))&&(!isAtEnd()))
            {
                if(peek()!='\\'){
                s ~= advance();}else{advance();}
            }
            if(peek()==';')advance();
            consume('"',"No closing quote found");
            addToken(TokenType.STRING, s);
            return;
        case '/':
            string s;
            if (peek() != '*'){
            consume(c, "Expected slash");
            comment();
            }else{
                consume('*', "Expected star");
                cComment();
            }
            return;

        case ';':
            addToken(TokenType.SEMICOLON, ";");
            return;
        case ':':
            addToken(TokenType.COLON, ":");
            return;
        case ',':
            addToken(TokenType.COMMA, ",");
            return;
        case '#':
            string n;
            n~=c;

            while (isAlphanum(cast(char)peek())&&(!isAtEnd()))
            {
                n ~= advance();
            }
            if(n=="#define"){
                addToken(TokenType.DEFINE, n);
            }else if(n=="#include"){
                string f=Path(this.file).toAbsolute.parent.toString()~"/";
                advance();
                consume('"', "Expected quote");
                while((peek()!='"')&&(!isAtEnd())){
                    f~=advance();
                }
                consume('"', "Expected quote");
                f=Path(f).toAbsolute.toString();
                if(exists(f)){
                    string file=readText(f);
                    Tokenizer t=new Tokenizer();
                    t.scanTokens(file,f);
                    if(t.err)this.err=true;
                    t.tokens.length--;
                    this.tokens=t.tokens~this.tokens;
                    imports=true;
                }else{
                    error("Could not find include "~f);
                }
            }else{
                error("Unexpected string, "~n~" is not a valid token");
            }
            return;
        case '%':
            if(cast(string)[peek()] in registers){
                addToken(registers[cast(string)[peek()]],cast(string)[c,advance()]);
            }else{
                error("Unexpected character, "~c~" is not a valid register");
            }
            return;    
        default:
            if((c=='&')&&(isAlphanum(peek()))){
                string s;
                while ((isAlphanum(cast(char)peek()))&&(!isAtEnd()))
                {
                    s ~= advance();
                }
                addToken(TokenType.PTR,s);
            }else if(std.ascii.isDigit(cast(char)c)&&(peek()=='x')&&std.ascii.isDigit(cast(char)peekNext())){
                string n;
                advance();
                while ((std.ascii.isDigit(cast(char)peek()) || (peek() == '.' && isDigit(cast(char)peekNext())))&&(!isAtEnd()))
                {
                    n ~= advance();
                }
                addToken(TokenType.NUMBER,n.to!uint(16).to!string());
            }else if (std.ascii.isDigit(cast(char)c)||((cast(char)c =='-'))&&std.ascii.isDigit(cast(char)peek()))
            {
                string n;
                n~=c;
                while ((std.ascii.isDigit(cast(char)peek()) || (peek() == '.' && isDigit(cast(char)peekNext())))&&(!isAtEnd()))
                {
                    n ~= advance();
                }
                addToken(TokenType.NUMBER, n);
                
            }else if (isAlphanum(cast(char)c)){
                string n;
                n~=c;
                while ((isAlphanum(cast(char)peek()))&&(!isAtEnd()))
                {
                    n ~= advance();
                }
                if(n[n.length-1]==':'){addToken(TokenType.LABEL,n);}
                else  if(!(n in keywords))addToken(TokenType.IDENTIFIER,n);
                else addToken(keywords[n],n);
            }else{
                error("Unexpected character, "~c);
            }
            
            return;
        }
    }
    bool isAlphanum(char c){
        return std.ascii.isAlpha(c) || std.ascii.isDigit(c)||c=='_'||c==':'||c=='.';
    }
        void comment(){
            while ((peek() != '\n')&&(!isAtEnd()))
            {
                advance();
            }
            return;
        }
        void cComment(){
            while ((peek() != '*')&&(!isAtEnd())){
                advance();
            }
            consume('*', "Expected star");
            consume('/', "Expected slash");
            return;
        }    
        void scanTokens(string src,string file,int line=1)
        {
            this.source = src;
            this.pos = 0;
            this.col=0;
            this.line=line;
            this.file=file;
             
            while (!isAtEnd())
            { 
                
                start = pos;
               
                scanToken(this.source);
            }
            TokenType eof = TokenType.EOF;
            addToken(eof);
        }

        void addToken(Token t)
        {
            t.line=line;
            t.col=cast(int)(col-t.literal.length);
            tokens.length++;
            tokens[tokens.length - 1] = t;
        }

        void addToken(TokenType type)
        {
            Token t;
            t.type = type;
            addToken(t);
        }

        void addToken(TokenType type, string l)
        {
            Token t;
            t.type = type;
            t.literal = l;
            addToken(t);
        }

        bool isAtEnd()
        {
            return pos >= source.length;
        }

        char advance()
        {   
            if(!isAtEnd()){
            col++;
            return source[pos++];}else{return cast(char)0;}
        }
    char consume(char c, string err)
        {
            if (check(c))
                return advance();
           error(err);
            return cast(char)0;
        }
        bool check(char c)
        {
            if (isAtEnd())
                return false;
            return peek() == c;
        }
        char peek()
        {
            if (isAtEnd())
                return cast(char)0;
            return source[pos];
        }
    char previous(){
        if (isAtEnd())
                return cast(char)0;
        return source[pos-1];
    }
        char peekNext()
        {
            if (pos + 1 >= source.length)
                return cast(char)0;
            return source[pos + 1];
        }

        bool match(char c)
        {
            if (isAtEnd())
                return false;
            if (source[pos] != c)
                return false;
            col++;
            pos++;
            return true;
        }
        void error(string msg){
            err=true;
            cwrite((file~"("~line.to!string()~","~col.to!string()~"): ").color(mode.bold));
            cwrite(("Error: ").color(fg.red).color(mode.bold));
            cwriteln(msg.color(mode.bold));

        }
    }

    class Parser
    {
        Token[] tokens;
        int pos;
        bool err;
        Statement[] stmts;
        string file;
        TokenType[] cmdlist=[TokenType.ADD,TokenType.BREAKPOINT,TokenType.JG,TokenType.JNG,TokenType.MOD,TokenType.DIV,TokenType.ADDF,TokenType.SUB,TokenType.SUBF,TokenType.MULF,TokenType.NOP,TokenType.MUL,TokenType.AND,TokenType.NOT,TokenType.OR,TokenType.XOR,TokenType.CP,TokenType.JMP,TokenType.JNZ,TokenType.JZ,TokenType.CMP,TokenType.SYS,TokenType.PUSH,TokenType.POP,TokenType.READ,TokenType.WRITE,TokenType.CALL,TokenType.RET,TokenType.INC,TokenType.INCF,TokenType.DEC,TokenType.DECF,TokenType.EXIT,TokenType.SETERRADDR,TokenType.MOV];

        void parse(Token[] tokens,string file){
            this.file=file;
             this.tokens = tokens;
             while(!isAtEnd()){
                parseTokens();
             }
        }
        void addStmt(Statement stmt){
            stmts.length++;
            stmts[stmts.length-1]=stmt;
        }
        void parseTokens(){
            TokenType cmd=matchTTs(this.cmdlist,tokens[pos]);
            bool define=check(TokenType.DEFINE);
            bool label=check(TokenType.LABEL);
            bool num=check(TokenType.NUMBER);
            bool str=check(TokenType.STRING);
            //writeln(peek(),cmd,define,label,num,str);
            if(cmd!=TokenType.NONE){
                advance();
                Token[] tlist=consumeUntil(TokenType.SEMICOLON);
                Token[] args;
                foreach(Token t;tlist){
                    
                    if(t.type!=TokenType.COMMA){
                        args.length++;
                        args[args.length-1]=t;
                    }
                    if(matchTTs(this.cmdlist,t)!=TokenType.NONE){
                        error("Expected semicolon",t.line,t.col);
                    }
                }
                
                addStmt(makeCmdStmt(cmd,args));
                consume(TokenType.SEMICOLON,"Expected semicolon");
            }else if(label){

                addStmt(makeLabelDefStmt(advance().literal.replace(":",""),pos-1));
            }else if(define){
                advance();
                string name=consume(TokenType.IDENTIFIER,"Expected identifier").literal;
                addStmt(makeDefineStmt(name,consumeUntil(TokenType.SEMICOLON)));
               
                consume(TokenType.SEMICOLON,"Expected semicolon");
            }else if(num){
                Token[] tvalues=consumeUntil(TokenType.SEMICOLON);
                real[] values;
                for(int i=0;i<tvalues.length;i++){
                    try{
                        if(tvalues[i].type!=TokenType.COMMA){
                    values ~= cast(real)tvalues[i].literal.to!real();}
                    }catch(Exception e){
                        error("Expected number, got "~tvalues[i].literal);
                    }
                }
                addStmt(makeNumStmt(values));
                consume(TokenType.SEMICOLON,"Expected semicolon");
            }else if(str){
                addStmt(makeStringStmt(advance().literal));
                consume(TokenType.SEMICOLON,"Expected semicolon");
            }else if(peek().type==TokenType.SEMICOLON){
                consume(TokenType.SEMICOLON,"Expected semicolon");
            }else{
                error("Expected command, label, define, number or string, not "~peek().literal);
            }
        }
        Token consume(TokenType t, string err)
        {
            if (check(t)){
                return advance();
            }else{
            error(err);
            }
            return Token(); 
        }
        Token[] consumeUntil(TokenType t){
            Token[] tlist;
            while((peek().type!=t)&&(!isAtEnd())){
                tlist ~= advance();
            }       
            return tlist;
        }
        void match(TokenType t,string err){
            if (!check(t))error(err);
        }
        TokenType matchTTs(TokenType[] tlist,Token t){
            for(int i=0; i<tlist.length;i++){
                if(t.type==tlist[i])return tlist[i];
            }
            return TokenType.NONE;
        }
        bool check(TokenType t)
        {
            if (isAtEnd())
                return false;
            return peek().type == t;
        }

        Token advance()
        {
            if (!isAtEnd())
                pos++;
            return previous();
        }

        bool isAtEnd()
        {
            return peek().type == TokenType.EOF;
        }

        Token peek()
        {
            return tokens[pos];
        }

        Token previous()
        {
            return tokens[pos - 1];
        }

        void error(string msg){
            error(msg,peek().line,peek().col);

        }
        void error(string msg,int line,int col){
            err=true;
            cwrite((file~"("~line.to!string()~","~col.to!string()~"): ").color(mode.bold));
            cwrite(("Error: ").color(fg.red).color(mode.bold));
            cwriteln(msg.color(mode.bold));
        }
    }
class Compiler{
        Statement[] stmts;
        string file;
        int pos;
        bool err;
        bool imports;
        real[] bytecode;
        int bcpos;
        Token[][string] defines;
        int[string] labels;
        string[int] unresolvedRefs;
        int[int] unResolvedData;
        real[][] dataSec;
        string[] dataSecMap;
        int dataPtr;
        int[TokenType] commands=[TokenType.NOP:0,TokenType.NONE:0,TokenType.ADD:1,TokenType.SUB:2,TokenType.MUL:3,TokenType.ADDF:4,TokenType.SUBF:5,TokenType.MULF:6,TokenType.AND:7,TokenType.NOT:8,TokenType.OR:9,TokenType.XOR:10,TokenType.CP:11,TokenType.JMP:12,TokenType.JNZ:13,TokenType.JZ:14,TokenType.CMP:15,TokenType.SYS:16,TokenType.READ:17,TokenType.WRITE:18,TokenType.PUSH:19,TokenType.POP:20,TokenType.MOV:21,TokenType.CALL:22,TokenType.RET:23,TokenType.INC:24,TokenType.DEC:25,TokenType.INCF:24,TokenType.DECF:25,TokenType.SETERRADDR:26,TokenType.EXIT:27,TokenType.DIV:28,TokenType.MOD:29,TokenType.BREAKPOINT:30,TokenType.JG:31,TokenType.JNG:32];
        real[TokenType] regs=[TokenType.REG_A:4294967296 - 9,TokenType.REG_B:4294967296 - 8,TokenType.REG_C:4294967296 - 7,TokenType.REG_D:4294967296 - 6,TokenType.REG_E:4294967296 - 5,TokenType.REG_F:4294967296 - 4,TokenType.REG_G:4294967296 - 3,TokenType.REG_H:4294967296 - 2,TokenType.REG_I:4294967296 - 1,TokenType.REG_J:4294967296 - 0];

        real[] resolveData(string name){
            if(!(dataSecMap.canFind(name))){
                dataSecMap~=name;
                dataSec~=compileTokens(defines[name]);
            }
            unResolvedData[bcpos]=cast(int)dataSecMap.countUntil(name);
            return [-1];
        }
        real[] compileTokens(Token[] tks){
            real[] res;
            foreach(Token tk;tks){res~=compileToken(tk);};
            return res;
        }
        void comp(string source,string file,bool d){
            this.file=file;
            Tokenizer t=new Tokenizer();
            Parser p=new Parser();
            t.scanTokens(source,file);
            if(t.err)return;
            this.imports=t.imports;
            if(d)writeln("Tokens: ",t.tokens);
            p.parse(t.tokens,file);
            if(p.err)return;
            stmts=p.stmts;
            parsePrePass();
            while(!isAtEnd()){
                compileStmt(peek());
            }
            parsePostPass();
        }
        void parsePrePass(){
            foreach(Statement stmt;this.stmts){
                if(stmt.type==StmtType.DEFINE){
                    defines[stmt.props.dd.name]=stmt.props.dd.value;
                }else if(stmt.type==StmtType.LABEL_DEF){
                    labels[stmt.props.ld.name]=-1;
                    
                }
            }
        }
        void parsePostPass(){
            //error handling fix;
            addBytecode(27);
            dataPtr=bcpos;
            foreach(real[] c;dataSec){addBytecode(c);}
            foreach(int pos,string name;unresolvedRefs){
                if(labels[name]!=0){
                    bytecode[pos]=labels[name];
                }
            }
            foreach(int pos,int dataPos;unResolvedData){
                int realPos=0;
                for(int i=0;i<dataPos;i++){
                    realPos+=dataSec[i].length;
                } 
                bytecode[pos]=realPos+dataPtr;
            }
        }
        void resolveLabel(string name){
            labels[name]=bcpos;
        }
        void addBytecode(real val){
            bytecode.length++;
            bcpos++;
            bytecode[bytecode.length-1]=val;
        }
        void addBytecode(real[] val){
            foreach(real value;val){addBytecode(value);}
        }
        void compileStmt(Statement stmt){
            switch(stmt.type){
                case StmtType.COMMAND:
                    addBytecode(getCmdValue(stmt.props.cd.cmd));
                    if((stmt.props.cd.cmd==TokenType.JMP||stmt.props.cd.cmd==TokenType.JNZ||stmt.props.cd.cmd==TokenType.JZ)&&(stmt.props.cd.oprands[0].type==TokenType.NUMBER)){
                        cwrite((file~"("~stmt.props.cd.oprands[0].line.to!string()~","~stmt.props.cd.oprands[0].col.to!string()~"): ").color(mode.bold));
                        cwrite(("Warning: ").color(fg.yellow).color(mode.bold));
                        cwriteln("Using fixed jump addresses with includes is not recommended, as inculded files could break them".color(mode.bold));
                    }
                    foreach(Token tk;stmt.props.cd.oprands){
                        addBytecode(compileToken(tk));
                    }
                    break;
                case StmtType.NUM:  
                foreach(real val;stmt.props.nd.values){
                    addBytecode(val);
                }
                break;
                default:
                break;
                case StmtType.LABEL_DEF:
                    resolveLabel(stmt.props.ld.name);
                    break;
                case StmtType.STRING:
                    addBytecode(handleString(stmt.props.sd.value));
                    break;    
            }
            advance();
            
        }
        int getCmdValue(TokenType cmd){
            if(commands.keys().canFind(cmd)){
                return commands[cmd];
            }

            return -1;
        }
        real getRegValue(TokenType reg){
            if(regs.keys().canFind(reg)){
                return regs[reg];
            }
            return -1;
        }
        
        real[] compileToken(Token token){
            if(getCmdValue(token.type)!=-1){return [getCmdValue(token.type)];}
            if(getRegValue(token.type)!=-1){return [getRegValue(token.type)];}
            switch(token.type){
                case TokenType.NUMBER:
                return [token.literal.to!real()];
                case TokenType.COMMA:
                return [];
                case TokenType.ARRAY:
                return compileTokens(token.subtokens);
                case TokenType.IDENTIFIER:
                if(defines.keys().canFind(token.literal)){
                    return compileTokens(defines[token.literal]);
                }else if(labels.keys().canFind(token.literal)){
                    if(labels[token.literal]==-1)unresolvedRefs[bcpos]=token.literal;
                    return [labels[token.literal]];
                }
                error("No such identifier, "~token.literal,token.line,token.col);
                return [0];
                case TokenType.PTR:
                if(defines.keys().canFind(token.literal)){
                    return resolveData(token.literal);
                }
                error("No such identifier, "~token.literal,token.line,token.col);
                return [0];    
                case TokenType.STRING:
                    return handleString(token.literal);
                case TokenType.FALSE:
                return [0];
                case TokenType.TRUE:
                return [1];
                case TokenType.NULL:
                return [0];    
                default:
                error("Error while compiling token, "~token.literal,token.line,token.col);
                  return [0];
            }
        }
        real[] handleString(string raw){
            real[] str;
                    foreach(char c;raw){
                        str~=cast(real)c;
                    }
                    str~=0;
                    return str;
        }
        Statement peek(){
            return stmts[pos];
        }
        Statement advance(){
            pos++;
            return stmts[pos-1];
        }
        bool isAtEnd(){
            return pos>=stmts.length;
        }
        void error(string msg,int line,int col){
            err=true;
            cwrite((file~"("~line.to!string()~","~col.to!string()~"): ").color(mode.bold));
            cwrite(("Error: ").color(fg.red).color(mode.bold));
            cwriteln(msg.color(mode.bold));
        }
    }