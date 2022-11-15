<template>
    <div class="login">
        <button class="dialog-open-button" @click="showDialog()">Login</button>

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
                    <div class="user">
                        <span>User：</span><input type="text" class="user-name" v-model="userName">
                    </div>
                    <div class="word">
                        <span>Password：</span><input type="password" class="password" v-model="password">
                    </div>
                    <div class="hangle-login"> 
                        <button class="login-button" @click="login()">Login</button>
                    </div>
                </div>
            </div>
        </div>
        
    </div>
</template>

<script>
    export default{
        data(){
            return {
                isShow : false,
                userName : '',
                password : '',
                token : ''
            }
        },
        methods: {
            showDialog(){
                this.isShow = true;
            },
            closeDialog(){
                this.isShow = false;
            },
            login() {
                let xmlHttpRequest = new XMLHttpRequest();
                xmlHttpRequest.withCredentials = false;
                xmlHttpRequest.open('GET', `http://159.75.110.59:8080/user/login?userName=${this.userName}&userPwd=${this.password}`);
                xmlHttpRequest.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                xmlHttpRequest.send();
                xmlHttpRequest.onreadystatechange = () => {
                    if(xmlHttpRequest.readyState === 4){
                        if(xmlHttpRequest.status === 200 || xmlHttpRequest === 304){
                            let tempRes = JSON.parse(xmlHttpRequest.responseText)
                            // let tempRes = xmlHttpRequest.responseText
                            this.token = tempRes.data;
                            // console.log(this.token)
                            localStorage.setItem('token', this.token);
                            // console.log(localStorage.getItem('token'));
                        }
                    }
                }
            }
        }
    }
</script>

<style scoped>
    .login{
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
    .login-button {
        color: #fff;
        padding: 10px 15px;
        border-radius: 6px;
        outline: none;
        border: unset;
        cursor: pointer;
        background-color: #2c2c2c;
        box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
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
    /* 登录 */
    .user,
    .word{
        display: flex;
        align-items: center;
        /* justify-content: end; */
    }
    .user-name,
    .password{
        margin: 10px 0;
        padding: 5px 0;
        justify-self: flex-end;
        align-self: end;
    }
    .hangle-login{
        align-items: end;
    }
</style>

