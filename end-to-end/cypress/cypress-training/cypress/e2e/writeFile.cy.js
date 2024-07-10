context('Files', () => {
    it('cy.writeFile() - write to a file', () => {
        const content = "bar";
        const filePath = "foo.txt";
        cy.writeFile(filePath, content);
    });
});