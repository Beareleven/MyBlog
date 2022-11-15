<template>
    <div class="post-news">
        <button class="dialog-open-button" @click="showDialog()">发布动态</button>

        <div class="dialog" v-show="isShow">
            <!-- 不透明遮罩 -->
            <div class="dialog-modal"></div>

            <!-- 主体内容 -->
            <div class="dialog-main">
                <!-- 关闭dialog按钮 -->
                <div class="dialog-head">
                    <button class="dialog-close-button" @click="closeDialog()">X</button>

                </div>
                <!-- 内容区 -->
                <div class="dialog-content">
                    <textarea class="post-content" placeholder=" 分享比得到更快乐" rows="5" cols="100" v-model="textContent"></textarea>
                    <div class="post-pic">
                        <input style="display : none"/>
                        <input type="file" name="file" multiple = 'multiple' @change="handleImg" ref="picUpload" style="display : none"/> 
                        <button class="upload-img-button" @click="uploadImg">上传图片</button>
                        <!-- 图片预览 -->
                        <div class="preview" v-if="picBox.length">
                            <div class="preview-pic" v-for="item in picBox" :key = "item">
                                <img :src="item" alt="preview Error" class="pic">
                            </div>
                        </div>
                    </div>
                </div>

                <div class="dialog-foot">
                    <button class="cancel-post-button" @click="cancelPost()">取消</button>
                    <button class="confirm-post-button" @click="confirmPost()">确认发布</button>
                </div>
            </div>
        </div>
        
    </div>
</template>

<script>
    export default{
        data(){
            return {
                isShow: false,
                textContent: '',
                // 图片数组
                picBox : [],
                // form
                picFormData : new FormData(),
                // 头像
                avatar:'http://159.75.110.59:9002/bear.jpg',
                nickName: 'Bear',

            }
        },
        methods: {
            showDialog(){
                this.isShow = true;
            },
            closeDialog(){
                this.textContent = '';
                this.picBox = [];
                this.isShow = false;
            },
            cancelPost(){
                // 清空输入框里的东西并关闭dialog
                // 清空
                this.textContent = '';
                this.picBox = [];
                // 关闭
                this.isShow = false;
            },
            confirmPost(){
                // 请求数据封装
                this.picFormData.append('avatar', this.avatar);
                this.picFormData.append('text', this.textContent);
                this.picFormData.append('nickname', this.nickName);

                let xmlHttpRequest = new XMLHttpRequest();
                xmlHttpRequest.open('POST', 'http://159.75.110.59:8080/postDynamic');
                // xmlHttpRequest.setRequestHeader('Content-Type', 'multipart/form-data');
                // xmlHttpRequest.send(`avatar=${this.avatar}&nickname=${this.nickName}&text=${this.textContent}&pic=@${this.uploadpic}`);
                xmlHttpRequest.send(this.picFormData)
                xmlHttpRequest.onreadystatechange = () => {
                    if(xmlHttpRequest.readyState === 4){
                        if(xmlHttpRequest.status === 200 || xmlHttpRequest === 304){
                            console.log(xmlHttpRequest.responseText)
                        }
                    }
                }
                // 清空
                this.textContent = '';
                this.picBox = [];
                // 关闭
                this.isShow = false;
            },
            handleImg(e){
                let files = e.target.files;
                // console.log(files)
                if(files.length > 0 && files.length <= 8){
                    // 遍历得到的图片数组，预览
                    // 通过URL.
                    for(let i = 0; i < files.length; i++){
                        console.log(files[i])
                        // this.uploadpic.push(files[i].name);
                        let pic = this.previewImg(files[i]);
                        this.picBox.push(pic);
                    }
                }else{
                    alert('选择图片过多，请重新选择')
                }

                // 使用formData存储图片信息，便于后续发送请求
                let formData = new FormData();
                for(let i = 0; i < files.length; i++){
                    formData.append('pic', files[i], files[i].name);
                    // console.log(formData.getAll('pic'))
                }
                // console.log(this.picFormData)
                this.picFormData = formData
                // console.log(this.picFormData.getAll('pic'))
            },
            uploadImg(){
                this.$refs.picUpload.click();
            },
            // previewImg
            previewImg(file){
                let url = URL.createObjectURL(file);
                return url;
            }
        }
    }
</script>

<style scoped>
    .post-news{
        margin: 0 auto;
        width: 80%;
        display: flex;
        justify-content: flex-end;
    }
    .dialog-open-button{
        margin-bottom: 15px;
    }
    .dialog-close-button,
    .dialog-open-button,
    .cancel-post-button,
    .confirm-post-button,
    .upload-img-button {
        color: #fff;
        padding: 10px 15px;
        border-radius: 6px;
        outline: none;
        border: unset;
        cursor: pointer;
        background-color: #2c2c2c;
        box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
    }
    .upload-img-button {
        margin-top: 5px;
    }
    .dialog{
        width: 60%;
        height: 330px;
        border-radius: 15px;
        opacity: 0.9;
        background: #adadad;
        position: fixed;
        top: 0;
    }
    .dialog-head{
        position: absolute;
        top: 20px;
        right: 30px;
    }
    .dialog-content{
        width: 80%;
        position: absolute;
        top: 80px;
        left: 70px;
        
    }
    .post-content{
        width: 100%;
        border-radius: 10px;
    }
    .dialog-foot{
        position: absolute;
        bottom: 30px;
        right: 30px;
    }

    /* 图片预览 */
    .preview{
        display: grid;
        grid-template-rows: 120px 120px 120px 120px;
        grid-template-columns: 120px 120px 120px 120px;
        grid-column-gap: 10px;
    }
    .preview-pic{
        width: 100%;
        background-color: rgba(44, 62, 80, .1);
        border-radius: 5%;
        margin-top: 5px;
        margin-right: 5px;
        overflow: hidden
    }
    .pic{
        width: 100%;
        height: 100%;
        display:inline-block;
    }
</style>
