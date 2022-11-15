<template>
    <div class="main">
        <div class="input">
            <div class="input-title">
                <span>输入你想转换的HTML</span>
                <button @click="htmlToAst">转换</button>
            </div>
            <textarea v-model="inputHtml" class="text" @keydown.tab="forbidTab($event)" @keyup.tab="replaceSpacing()"></textarea>
        </div>
        <div class="output">
            <div class="output-title">AST</div>
            <textarea v-model="outputHtml" class="text"></textarea>
        </div>
    </div>
</template>

<script>
    export default{
        data(){
            return{
                inputHtml: `<div>Vue</div>`,
                outputHtml: '',
                TextModes: {
                    DATA: 'DATA',
                    RCDATA: 'RCDATA',
                    RWATEXT: 'RWATEXT',
                    CDATA: 'CDATA',
                },
                // 命名字符引用表
                // 可以加入各种字符映射，填入之后才能解码实体字符
                namedCharacterReferences: {
                    'lt;' : '<',
                }
            }
        },
        created(){
            this.htmlToAst();
        },
        methods: {
            htmlToAst(){
                let tempJson = this.parse(this.inputHtml);
                console.log('tempJson', tempJson)
                this.outputHtml = JSON.stringify(tempJson, null, 4)
                // JSON.stringify(JSON.parse(jsondata), null, 4);
                console.log(this.outpuHtml)
            },
            // 解析器函数
            parse(str){
                const context = {
                    source: str,
                    mode: this.TextModes.DATA,    // 初始状态
                    advanceBy(num){
                        context.source = context.source.slice(num)
                    },
                    advanceSpaces(){
                        // 匹配空白字符
                        const match = /^[\t\r\n\f ]+/.exec(context.source);
                        if(match){
                            // 调用advanceBy 去消耗他
                            context.advanceBy(match[0].length)
                        }
                    }
                };
                // debugger
                const nodes = this.parseChildren(context, []);

                return {
                    type: 'Root',
                    children: nodes
                }
            },

            // parseChildren 函数，会返回解析后的子节点，接收两个参数
            // 第一个参数：context，上下文对象，维护程序执行过程中的状态
            // 第二个参数：由父代节点构成的节点栈，用于维护节点间的父子关系，初始为空

            // parseChildren 状态机分类
            // 1.标签节点 2.普通文本节点 3.注释节点 4.CDATA节点 (5.文本插值节点，{{val}})
            parseChildren(context, parents) {
                // console.log("parseChildren", context.source)
                // 存储子节点，最后将返回出去
                let nodes = [];
                // 从上下文对象中接受模版内容和当前状态
                // const {mode, source} = context;
                // 开启while循环，只要满足条件就一直对字符串进行解析
                while(!this.isEnd(context, parents)) {
                    let node
                    // 只有在DATA 和 RCDATA 模式下才支持 插值节点的解析
                    if(context.mode === this.TextModes.DATA || context.mode === this.TextModes.RCDATA){
                        // 只有在DATA模式下才支持标签节点的解析
                        // 这个算是一个临时状态，需要知道后续是什么字符串，才能知道要像哪个状态变更
                        // console.log('pc', source)
                        if(context.mode === this.TextModes.DATA && context.source[0] === '<'){
                            if(context.source[1] === '!'){
                                // console.log(source[1])
                                if(context.source.startsWith('<!--')){
                                    // 注释状态
                                    node = this.parseComment(context)
                                    // console.log('注释处理后', context.source)
                                }else if(context.source.startsWith('<![CDATA[')){
                                    // CADATA状态
                                    node = this.parseCDATA(context, parents)
                                }
                            }else if(context.source[1] === '/'){
                                console.error('无效的结束标签')
                                continue;
                            }else if(/[a-z]/i.test(context.source[1])){
                                // console.log('标签')
                                // 解析标签状态
                                node = this.parseElement(context, parents)
                            }
                        }else if(context.source.startsWith('{{')){
                            // 解析插值
                            node = this.parseInterpolation(context);
                        }
                    }

                    // 如果处于非DATA 并且 非RCDATA 模式下，这时不会再走上面的逻辑，node依旧是undefined
                    // 这时所有内容都看作文本处理
                    if(!node){
                        node = this.parseText(context)
                    }
                    nodes.push(node);
                }
                // 子节点解析完毕，返回
                return nodes;
            },

            isEnd(context, parents){
                if(!context.source) return true;

                // 与父级节点栈内所有节点做比较
                for(let i = parents.length - 1; i >= 0; i--){
                    if(context.source.startsWith(`</${parents[i].tag}`)){
                        return true;
                    }
                }
                return false;
            },

            // parseElement 函数：解析开始标签、解析子节点、解析结束标签
            parseElement(context, parents){
                // console.log("parseElement", context.source)
                // parseTag 用于解析开始标签，包括标签上的属性 和 （Vue中的指令）
                const element = this.parseTag(context);
                // 自闭合标签
                if(element.isSelfClosing) return element;

                // 状态切换
                if(element.tag === 'textarea' || element.tag === 'title'){
                    context.mode = this.TextModes.RCDATA
                }else if(/style|xmp|iframe|noembed|noframes|noscript/.test(element.tag)){
                    context.mode = this.TextModes.RWATEXT
                }else{
                    context.mode = this.TextModes.DATA
                }

                // 解析完开始标签后，就递归调用 parseChildren里解析子节点
                parents.push(element);
                element.children = this.parseChildren(context, parents);
                parents.pop();

                // 最后调用parseEndTag 来处理结束标签
                if(context.source.startsWith(`</${element.tag}`)){
                    // 再次调用parseTag 函数解析结束标签，同时标记为 end，结束标签
                    this.parseTag(context, 'end')
                }else{
                    console.error(`${element.tag} 标签缺少闭合标签`)
                }
                return element;
            },

            // parseTag函数需要同时处理开始标签和结束标签，所以我们利用第二个参数来进行一个标记，初始值为start
            parseTag(context, type = 'start') {
                // console.log("parseTag", context.source)
                
                // 获取消耗处理函数
                const {advanceBy, advanceSpaces} = context;

                // 处理标签（开始结束分别处理）
                // console.log(type)
                // console.log(context.source)
                const match = type === 'start'
                // 匹配到开始标签
                ? /^<([a-z][^\t\r\n\f />]*)/i.exec(context.source)
                // 匹配到结束标签
                : /^<\/([a-z][^\t\r\n\f />]*)/i.exec(context.source)
                // console.log(match)
                const tag = match[1]
                advanceBy(match[0].length)
                advanceSpaces()

                // 调用 parseAttributes 函数来完成属性和指令的解析，并得到props数组
                const props = this.parseAttributes(context)

                // 自闭合标签
                const isSelfClosing = context.source.startsWith('/>')
                advanceBy(isSelfClosing ? 2 : 1)

                return {
                    type : 'Element',
                    tag: tag,
                    props,
                    children: [],
                    isSelfClosing: isSelfClosing
                }
            },

            parseAttributes(context){
                // console.log("parseAttributes", context.source)

                const {advanceBy, advanceSpaces} = context;
                const props = [];
                // console.log(context.source)
                // 在没遇到闭合标签时，解析属性或者指令
                while(!context.source.startsWith('>') && !context.source.startsWith('/>')){
                    // 匹配属性名称
                    const match = /^[^\t\r\n\f />][^\t\r\n\f />=]*/.exec(context.source);
                    const name = match[0];

                    // 每次匹配完都得记得消耗
                    advanceBy(name.length);
                    advanceSpaces();
                    // 消耗等于号
                    advanceBy(1);
                    advanceSpaces();

                    // 属性值
                    let val = '';
                    const quote = context.source[0];
                    // 单引号或者双引号
                    const isQuote = quote === '"' || quote ==="'";

                    if(isQuote) {
                        advanceBy(1);
                        const endQuoteIndex = context.source.indexOf(quote);
                        if(endQuoteIndex !== -1) {
                            val = context.source.slice(0, endQuoteIndex);
                            advanceBy(val.length);      // 消耗属性值
                            advanceBy(1);       // 消耗后面的引号
                        }else{
                            console.error('缺少引号')
                        }
                    }else{
                        // 属性没有被引号印用，因此到下一个空白字符之前，都是属性值
                        const match = /^[^\t\r\n\f />]+/.exec(context.source);
                        val = match[0];
                        advanceBy(val.length);
                    }
                    advanceSpaces();

                    props.push({
                        type: 'Attribute',
                        name: name,
                        value: val
                    })
                }
                return props;
            },

            // 解析文本节点
            parseText(context){
                console.log("parseText", context.source)

                // 寻找文本节点的结尾位置
                // 1. < 标签开始
                // 2. {{ 插值表达式
                
                // 初始化endIndex
                let endIndex = context.source.length;
                const ltIndex = context.source.indexOf('<');
                const interIndex = context.source.indexOf('{{');

                if(ltIndex !== -1 && ltIndex < endIndex) endIndex = ltIndex;
                if(interIndex !== -1 && interIndex < endIndex) endIndex = interIndex;

                // 切割出文本节点内容
                const content = context.source.slice(0, endIndex);
                // 记得消耗
                context.advanceBy(content.length);

                return {
                    type : 'Text',
                    content: this.decodeHTML(content)
                }
            },

            // 解析HTML实体
            // HTML实体用来描述一些如：保留字符、难以用键盘键入的字符、不可见的字符
            // 比如用 &lt 表示 < 实体总是以 '&' 开头 ';' 结尾
            // asAttr 作为属性，一些url所带的参数也是使用 & 开头的
            decodeHTML(rawText, asAttr = false) {
                let offset = 0;
                const endIndex = rawText.length;
                let decodedText = '';
                let maxCRnameseLength = 0;

                function advance(num){
                    offset += num;
                    rawText = rawText.slice(num);
                }

                while(offset < endIndex){
                    const head = /&(?:#x?)?/i.exec(rawText);
                    // 匹配不到，说明没有需要解码的内容了
                    if(!head){
                        const remaining = endIndex - offset;
                        decodedText += rawText.slice(0, remaining);
                        advance(remaining);
                        break;
                    }
                    // 截取 & 之前的字符加入我们的 decodedText，然后消耗他
                    decodedText += rawText.slice(0, head.index);
                    advance(head.index);

                    if(head[0] === '&'){
                        let value, name = '';
                        // 字符 & 下一个字符必须是 ASCII 字母或数字，这样才能命中合法的命名字符引用
                        if(/[0-9a-z]/i.test(rawText[1])){
                            if(!maxCRnameseLength){
                                maxCRnameseLength = Object.keys(this.namedCharacterReferences).reduce((max, name) => Math.max(max, name.length), 0);
                            }

                            for(let length = maxCRnameseLength; !value && length > 0; length--){
                                name = rawText.substr(1, length);
                                value = this.namedCharacterReferences[name];
                            }
                
                            if(value){
                                // 匹配到了，检查最后字符是不是分号
                                const semi = name.endsWith(';');
                                // 如果不是分号
                                if(asAttr && !semi && /[=a-z0-9]/i.test(rawText[name.length + 1] || '')){
                                    decodedText += '&' + name;
                                    advance(1 + name.length);
                                }else{
                                    // 是分号，解码
                                    decodedText += value;
                                    advance(1 + name.length)
                                }
                            }else{
                                // 没有匹配到，解码失败
                                decodedText += '&' + name;
                                advance(1 + name.length);
                            }
                        }else{
                            // & 下一个字符不是字母也不是数字，& 作为普通文本解析
                            decodedText += '&';
                            advance(1);
                        }
                    }
                }
                return decodedText;
            },

            // parseComment函数，用于解析注释节点
            parseComment(context) {
                console.log("parseComment", context.source)

                context.advanceBy('<!--'.length);
                let closeIndex = context.source.indexOf('-->');
                const content = context.source.slice(0, closeIndex);
                context.advanceBy(content.length);
                context.advanceBy('-->'.length);
                return {
                    type : 'Comment',
                    content
                }
            },

            // parseInterpolation 函数，解析插值表达式
            parseInterpolation(context) {
                context.advanceBy('{{'.length);
                let closeIndex = context.source.indexOf('}}');
                if(closeIndex === -1){
                    console.error('缺少结束 }} ')
                }

                const content = context.source.slice(0, closeIndex);
                context.advanceBy(content.length);
                context.advanceBy('}}'.length);

                return {
                    type : 'Expression',
                    content: this.decodeHTML(content)
                }
            },
            forbidTab(e){
                e.preventDefault();
            },
            replaceSpacing(){
                this.inputHtml += " ";
            },
        }
    }
</script>

<style>
    .main {
        display: flex;
        justify-content: space-around;
    }
    .input {
        width: 35%;
    }
    .input-title {
        padding: 10px;
        display: flex;
        justify-content:space-around;
    }
    .output-title{
        padding: 10px;
    }
    .output {
        width: 55%;
    }
    .text {
        width: 100%;
        height: 60vh;
        /* padding: 20px; */
        /* margin: 20px; */
    }
</style>
