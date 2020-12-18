import Foundation


enum Role{
    case admin
    case regularUser
}

enum RegistretionErrors: Error{
    case userAlreadyExist
    case badPassword
    case badUserName
}

enum AuthErrors: Error{
    case blockedUser
    case wrongAuthData
}

private protocol Registration{
    func createUsername(name: String) throws -> String
    func createPassword(password: String) throws -> String
    func chooseRole(role: Role) -> Role
}

protocol LogIn{
    func logIn(userName: String, password: String)  -> BettingSystem
    func isRegistered(userName: String) throws -> User
    func isBlocked(userName: String) throws
    func checkPassword(password: String) throws   
}

enum SystemState{
    case availableToRegistration
    case regularUserAuthoraized
    case adminAuthoraized
    case registrationInProcess
}


struct User{
    var userName: String
    var password: String
    var role: Role
    
    init(userName: String, passWord:String, role:Role) {
        self.userName = userName
        self.password = passWord
        self.role = role
    }
    
}

class BettingSystem{
    
    var users: [String: User] =  [:]
    var blockedUsers: [String: User] = [:]
    var userBets: [String:[String]] = [:]
    var systemState : SystemState
    var currentUser : User? = nil
    
    init() {
        self.systemState = SystemState.availableToRegistration
    }
    
    func makeBet(bet: String) -> BettingSystem{
        guard self.systemState == SystemState.regularUserAuthoraized else {
            print("You can't do this")
            return self
        }
        
        if var bets = self.userBets[self.currentUser!.userName]{
            bets.append(bet)
            self.userBets[self.currentUser!.userName] = bets
        }
        else {
            self.userBets[self.currentUser!.userName] = [bet]
        }
        
        return self
        
    }
    
    func printPlacedBets()-> BettingSystem {
        guard self.systemState == SystemState.regularUserAuthoraized else {
            print("You can't do this")
            return self
        }
        if let bets = userBets[self.currentUser!.userName] {
            bets.forEach{ print($0) }
        }
        return self
    }
    
    func printUsers() -> BettingSystem{
        guard self.systemState == SystemState.adminAuthoraized else {
            print("You can't do this. If you want to use this function move to login, firstly ")
            return self
        }
        self.users.keys.forEach{
            if(self.users[$0]!.role == Role.regularUser){
                print($0)
            }
        }
        return self
    }
    
    func logOut() -> BettingSystem{
        self.currentUser = nil
        self.systemState = SystemState.availableToRegistration
        return self
    }
    
    func blockedUser(userName: String) -> BettingSystem {
        guard self.systemState == SystemState.adminAuthoraized else {
            print("You can't do this.You are regularUser")
            return self
        }
        self.blockedUsers.updateValue(self.users[userName]!, forKey: userName)
        self.users[userName] = nil
        return self
    }
}
    


extension BettingSystem: LogIn{
    func logIn(userName: String, password: String)  -> BettingSystem{
        guard self.systemState == SystemState.availableToRegistration else {
            print("The system is busy.Now you can't enter in system")
            return self
        }
        do {
            try isBlocked(userName: userName)
        } catch AuthErrors.blockedUser,_{
            print("You are not allowed to registration.You are in black list")
            return self
        }
        
        do {
            currentUser = try isRegistered(userName: userName)
        } catch AuthErrors.wrongAuthData,_{
            print("You write something wrong. Please try again, or you should make registration")
            return self
        }
        
        do {
            try checkPassword(password: password)
        } catch AuthErrors.wrongAuthData,_ {
            print("You write something wrong. Please try again, or you should make registration")
            return self
        }
        if currentUser!.role == Role.regularUser{
            self.systemState = SystemState.regularUserAuthoraized
        }else{
            self.systemState = SystemState.adminAuthoraized
        }
        print("Welcome you are in the betting system")
        return self
    }
    
    func isRegistered(userName: String) throws -> User{
        guard let user = self.users[userName] else {
            throw AuthErrors.wrongAuthData
        }
        return user
        
    }
    
    func isBlocked(userName: String) throws{
        guard self.blockedUsers[userName] == nil else {
            throw AuthErrors.blockedUser
        }
    }

    func checkPassword(password: String) throws {
        guard self.currentUser?.password == password else {
            throw AuthErrors.wrongAuthData
        }
    }
}
    

extension BettingSystem: Registration{
     func register(name: String, password: String, role: Role) ->  BettingSystem {
        guard self.systemState == SystemState.availableToRegistration else {
            print("You are not allowd to register.The system is busy.")
            return self
        }
        let tempName, tempPassword: String
        do {
            try tempName = createUsername(name: name)
        } catch RegistretionErrors.badUserName{
            print("Please change your username its nor appropriate.")
            return self
        }
        catch RegistretionErrors.userAlreadyExist, _{
            print("Ooops, user has already existed. Move on to login ")
            return self
        }
        
        do {
            tempPassword = try createPassword(password: password)
        } catch RegistretionErrors.badPassword, _{
            print("Bad password.Try again registration")
            return self
        }

        self.users[tempName] = User(userName: tempName, passWord: tempPassword, role: chooseRole(role: role))
        return self
    }
    
    
    func createPassword(password: String) throws -> String {
        guard password.count > 3  else {
            throw RegistretionErrors.badPassword
        }
        return password
    }

    func createUsername(name: String) throws -> String{
        guard(!self.users.keys.contains(name)) else {throw RegistretionErrors.userAlreadyExist}
        guard(name.count > 3) else {
            throw RegistretionErrors.badUserName
        }
        return name
        
    }

    func chooseRole(role: Role) -> Role{
        return role
    }
}


var bettingSystem = BettingSystem()
bettingSystem = bettingSystem.register(name: "Pasha", password: "pashok", role: Role.regularUser)
bettingSystem.logIn(userName: "Pasha", password: "pashok")
bettingSystem.makeBet(bet: "Milan-Jenoa: П1")
bettingSystem.makeBet(bet: "Динамо-Фиорентина: П1")
bettingSystem.blockedUser(userName: "Pasha")
bettingSystem.logIn(userName: "Pasha", password: "pashok")
bettingSystem.logOut()
bettingSystem.logIn(userName: "Pasha", password: "pashok")
bettingSystem.register(name: "Sasha", password: "green", role: Role.admin)
bettingSystem.logOut()
bettingSystem.register(name: "Sasha", password: "green", role: Role.admin)
bettingSystem.logIn(userName: "Sasha", password: "green")
bettingSystem.printUsers()
bettingSystem.blockedUser(userName: "Pasha")
bettingSystem.printUsers()
bettingSystem.logIn(userName: "Pasha", password: "green")
bettingSystem.logOut()
bettingSystem.logIn(userName: "Pasha", password: "green")
print(bettingSystem.users)

