<template>
	<div class="virtual-item">
    	<div class="outer">
			<div class="user-info">
				<div class="user-avatar">
					<img :src="item.avatar" alt="" width="100%" height="100%">
				</div>
				<div class="user-nickname">{{item.nickname}}</div>
			</div>
			<div class="post-content">
				<div class="text">{{item.text}}</div>
				<div class="pic">
					<img class="post-pic" v-for="pic in item.pic" :key="pic" :src="pic" alt="" width="100%" height="100%">
				</div>
			</div>
    	</div>
	</div>
</template>

<script>
	export default{
		props: ['item'],
    	data() {
      		return {

      		}
    	},
		created(){
			// console.log(this.props.item);
		},
		methods: {}
	}
</script>

<style scoped>
.outer{
	margin: 10px auto;
	width:80%;
	padding: 40px 30px;
	background-color: #f4f5f5;
	border-radius: 10px;
}
.user-info{
	display: flex;
	width: 80%;
	height: 50px;
	/* background-color: silver; */
	/* align-items: center; */
}
.user-avatar{
	display: flex;
	padding: 0 10px;
}
.user-avatar img{
	border-radius: 50%;
}
.user-nickname{
	font-size: 16px;
	align-self: center;
}
.post-content{
	width: 100%;
	margin: 15px;
	font-size:14px;
}
.text{
	margin: 10px;
}
.pic{
	display: flex;
	margin: 10px;
	width: 100%;
	flex-wrap: wrap;
	/* height:140px; */
}
.pic img{
	border-radius: 15px;
	padding: 5px;
	width: 140px;
	height:140px;
	align-self: center;
}
</style>


