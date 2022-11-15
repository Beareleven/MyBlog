<template>
<!-- 监听滚动事件，获取滚动位置scrollTop -->
    <div ref="list" :style="{ height }" class="virtual-list-container" @scroll="scrollEvent($event)">
        <!-- 占位，用于形成滚动条 -->
        <div ref="phantom" class="virtual-phantom"></div>
        <!-- 无限列表 -->
        <div ref="content" class="infinite-list">
            <div class="infinite-list-item" ref="items" v-for="item in visibleData" :key="item._index" :id="item._index">
                <slot ref="slot" :item="item.item"></slot>
            </div>
        </div>
    </div>
</template>

<script>
    export default{
        name: "VirtualList",
        data() {
            return {
                // 可视区域高度
                screenHeight: 0,
                // 可视列表的起始结束索引
                startIndex: 0,
                endIndex: 0,
            }
        },
        // 接收父组件传过来的数据
        props: {
            // 列表数据（ALL）
            listData: {
                type: Array,
                default: () => []
            },
            // 每一个item的预估高度
            pridictItemHeight: {
                type:Number,
                required: true
            },
            // 缓冲区比例（为了使页面滚动平滑，需要在可视区域到上下方渲染额外的项目，在滚动时给予缓冲，不提前渲染的话，可能会出现短暂白屏的现象）
            bufferScale: {
                type: Number,
                default: 1
            },
            // 容器高度
            height: {
                type: String,
                default: '50vh'
            }
        },
        watch : {
            listData : {
                handler(){
                    this.initPositions();
                }
            }
        },
        // 利用compute来动态获取渲染时需要的数据
        computed: {
            // 处理父组件传进来的列表, 为每一项添加一个索引
            _listData(){
                return this.listData.map((item, index) => {
                    return {
                        _index : `_${index}`,
                        item
                    }
                })
            },
            //可视区域显示数量
            visibleCount(){
                // 可视区域高度 除以 每项的预估高度 并向上取整即为 可视区域改渲染的动态个数
                return Math.ceil(this.screenHeight / this.pridictItemHeight)
            },
            // 缓冲区额外渲染的数量
            // 1. 上方
            aboveCount(){
                return Math.min(this.startIndex, this.bufferScale * this.visibleCount)
            },
            // 2. 下方
            belowCount(){
                return Math.min(this.listData.length - this.endIndex, this.bufferScale * this.visibleCount)
            },
            // 通过上面的几个方法，计算出应该渲染的动态条数
            visibleData(){
                // console.log(this.startIndex,this.endIndex, this.aboveCount,this.belowCount)
                let start = this.startIndex - this.aboveCount;
                let end = this.endIndex + this.belowCount;
                // console.log(this._listData, start, end, this.startIndex, this.endIndex)
                // console.log(this._listData.slice(start, end))
                return this._listData.slice(start, end);
            }
        },
        created(){
            // console.log('1')
            // this.initPositions();
            // console.log('1', this.positions)
            window.vm = this;
        },
        mounted(){
            this.screenHeight = this.$el.clientHeight;
            console.log('1', this.$el.clientHeight)
            // this.screenHeight = '10000';
            this.startIndex = 0;
            this.endIndex = this.startIndex + this.visibleCount;
            // console.log(this.end)
        },
        updated(){
            this.$nextTick(function(){
                if(!this.$refs.items || !this.$refs.items.length){
                    return ;
                }
                // 获取真实元素大小，修改对应的尺寸缓存
                this.updatePostHeight();
                // 更新此时的列表总高度
                let height = this.positions[this.positions.length - 1].bottom;
                // console.log(height)
                this.$refs.phantom.style.height = height + 'px';
                // 更新真实偏移量
                this.setStartOffset();
            })
        },
        methods: {
            // 定义一个positions，用于列表项渲染后存储 每一项的高度以及位置消息
            initPositions(){
                // console.log('初始化',this.listData);
                this.positions = this.listData.map((d, index) => {
                    return {
                        index,
                        height: this.pridictItemHeight,
                        top: index * this.pridictItemHeight,
                        bottom: (index + 1) * this.pridictItemHeight
                    }
                })
                // console.log('2', this.positions)
            },
            // 滚动事件
            scrollEvent(){
                // console.log('1')
                let scrollTop = this.$refs.list.scrollTop;
                // console.log(scrollTop)
                // 此时的开始索引（滚动后）
                this.startIndex = this.getStartIndex(scrollTop);
                // console.log(this.startIndex)
                // 此时的结束索引（滚动后）
                this.endIndex = this.startIndex + this.visibleCount;
                // 此时的偏移量
                this.setStartOffset();
            },
            getStartIndex(scrollTop){
                // 我们这接收动态列表时已经给我们每条动态都添加了一个_index，这个_index可以作为我们进行二分查找的索引
                // console.log(this.positions)
                return this.binarySearch(this.positions, scrollTop);
            },
            // 二分查找
            binarySearch(list, value){
                let start = 0;
                let end = list.length - 1;
                let tempIndex = null;

                while(start <= end){
                    let midIndex = Math.floor((start + end) / 2);
                    let midValue = list[midIndex].bottom;

                    if(midValue === value){
                        return midIndex + 1;
                    }else if(midValue < value){
                        start = midIndex + 1;
                    }else{
                        if(tempIndex === null || tempIndex > midIndex){
                            tempIndex = midIndex;
                        }
                        end = end - 1;
                    }
                }
                return tempIndex;
            },
            // 获取列表项的当前尺寸
            updatePostHeight(){
                let posts = this.$refs.items;
                posts.forEach((post) => {
                    let rect = post.getBoundingClientRect();
                    // console.log(rect)
                    let newHeight = rect.height;
                    let index = +post.id.slice(1);
                    let oldHeight = this.positions[index].height;
                    let dValue = oldHeight - newHeight;

                    // 如果存在差值
                    if(dValue){
                        this.positions[index].bottom = this.positions[index].bottom - dValue;
                        this.positions[index].height = newHeight;
                        for(let i = index + 1; i < this.positions.length; i++){
                            this.positions[i].top = this.positions[i - 1].bottom;
                            this.positions[i].bottom = this.positions[i].bottom - dValue;
                        }
                    }
                })

            },
            // 获取当前的偏移量
            setStartOffset(){
                let startOffset;
                if(this.startIndex >= 1){
                    let height = this.positions[this.startIndex].top - (this.positions[this.startIndex - this.aboveCount] ? this.positions[this.startIndex - this.aboveCount].top : 0);
                    startOffset = this.positions[this.startIndex - 1].bottom - height;
                }else{
                    startOffset = 0;
                }
                this.$refs.content.style.transform = `translate3d(0, ${startOffset}px, 0)`;
            },
        }
    }
</script>


<style scoped>
.virtual-list-container{
    overflow: auto;
    position: relative;
    -webkit-overflow-scrolling: touch;
}
.virtual-phantom{
    position: absolute;
    left: 0;
    top: 0;
    right: 0;
    z-index: -1;
}z
.infinite-list{
    left: 0;
    right: 0;
    top: 0;
    position: absolute;
}
.infinite-list-item {
    display: block;
    padding: 5px;
    color: #555;
    box-sizing: border-box;
    /* border-bottom: 1px solid #999; */
}
</style>


