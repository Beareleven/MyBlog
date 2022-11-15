<template>
    <VirtualList :listData="listData" :pridictItemHeight='340' v-slot="slotProps">
        <!-- <Item :listData="listData"/> -->
        <Item :item="slotProps.item"/>
    </VirtualList>
</template>

<script>
// import VirtualList from './VirtualList.vue';
    export default{
//   components: { VirtualList },
        data(){
            return{
                listData : [],
            }
        },
        created(){
            this.initListData();
        },
        methods: {
            initListData() {
                let xmlHttpRequest = new XMLHttpRequest();
                xmlHttpRequest.withCredentials = false;
                xmlHttpRequest.open('GET', 'http://159.75.110.59:8080/queryDynamic');
                xmlHttpRequest.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                xmlHttpRequest.send();
                xmlHttpRequest.onreadystatechange = () => {
                    if(xmlHttpRequest.readyState === 4){
                        if(xmlHttpRequest.status === 200 || xmlHttpRequest === 304){
                            let tempRes = JSON.parse(xmlHttpRequest.responseText)
                            this.listData = tempRes.data
                            // console.log(this.listData)
                        }
                    }
                }
            }
        }
    }
</script>

<style scoped>

</style>
